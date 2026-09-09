// Copyright (c) 2026 Dawid Kurek <hello@dawikur.dev>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

module Phase0 {
	class View extends WatchUi.WatchFace {
		// Update lifecycle:
		// - rebuildWidgets_ creates widgets and groups them by their desired
		//   full-update cadence after settings change.
		// - onLayout positions and sizes those widgets after layout changes.
		// - onUpdate refreshes and renders the full face. SEC widgets therefore
		//   update every second when the system provides full updates, such as
		//   while the user is viewing the watch face.
		// - onPartialUpdate is the low-power path between full updates: it clears
		//   and redraws only seconds, never other SEC widgets.

		typedef Bases as Lang.Array<Widgets.Base>;

		static const UPDATE_MODE_HIGH_POWER = 0;
		static const UPDATE_MODE_LOW_POWER = 1;
		static const UPDATE_MODE_LIMITED_POWER = 2;

		// ---- fields ----

		// -- base --
		// The device may still provide partial updates in low-power mode. This
		// becomes exhausted only when Garmin reports its partial-update budget
		// has been exceeded.
		hidden var update_mode_ as Lang.Number = UPDATE_MODE_HIGH_POWER;
		hidden var is_night_mode_ as Lang.Boolean = false;
		hidden var is_visible_ as Lang.Boolean = false;

		hidden var needs_reposition_ as Lang.Boolean = false;

		hidden var bitmap_ as Graphics.BufferedBitmap? = null;

		// -- refresh --
		hidden var last_refresh_min_ as Lang.Number = -1;
		hidden var last_refresh_hour_ as Lang.Number = -1;

		// -- widgets --
		hidden var status_ as Widgets.Base = Widgets.Base.None();
		hidden var gauges_ as Bases = [];

		hidden var clock_ as Widgets.Base = Widgets.Base.None();
		hidden var seconds_ as Widgets.Base = Widgets.Base.None();
		hidden var batteries_ as Bases = [];

		hidden var top_outer_ as Widgets.Base = Widgets.Base.None();
		hidden var top_middle_ as Bases = [];
		hidden var top_inner_ as Widgets.Base = Widgets.Base.None();

		hidden var bottom_inner_date_ as Widgets.Base = Widgets.Base.None();
		hidden var bottom_inner_am_pm_ as Widgets.Base = Widgets.Base.None();
		hidden var bottom_middle_ as Bases = [];
		hidden var bottom_outer_ as Widgets.Base = Widgets.Base.None();

		hidden var widgets_per_hour_ as Bases = [];
		hidden var widgets_per_min_ as Bases = [];
		hidden var widgets_per_sec_ as Bases = [];

		// ---- methods ----

		function initialize() {
			WatchFace.initialize();
		}

		function onShow() as Void {
			self.is_visible_ = true;
			self.invalidate_();
		}

		function onHide() as Void {
			self.is_visible_ = false;
		}

		function onEnterSleep() as Void {
			self.update_mode_ = UPDATE_MODE_LOW_POWER;

			WatchUi.requestUpdate();
		}

		function onExitSleep() as Void {
			self.update_mode_ = UPDATE_MODE_HIGH_POWER;

			WatchUi.requestUpdate();
		}

		function onSettingsChanged(_properties as Properties) as Void {
			self.rebuildWidgets_(_properties);

			WatchUi.requestUpdate();
		}

		function handlePowerBudgetExceeded() as Void {
			self.update_mode_ = UPDATE_MODE_LIMITED_POWER;

			WatchUi.requestUpdate();
		}

		function handlePress(
			_click_event as WatchUi.ClickEvent
		) as Lang.Boolean {
			var coordinates = _click_event.getCoordinates();
			var pos_x = coordinates[0];
			var pos_y = coordinates[1];

			if (self.clock_.contains(pos_x, pos_y)) {
				WatchUi.requestUpdate();

				return true;
			}

			if (!self.is_night_mode_) {
				var widgets_per_hour_size = self.widgets_per_hour_.size();
				for (var i = 0; i < widgets_per_hour_size; ++i) {
					var widget = self.widgets_per_hour_[i];
					if (widget.contains(pos_x, pos_y)) {
						return widget.open();
					}
				}

				var widgets_per_min_size = self.widgets_per_min_.size();
				for (var i = 0; i < widgets_per_min_size; ++i) {
					var widget = self.widgets_per_min_[i];
					if (widget.contains(pos_x, pos_y)) {
						return widget.open();
					}
				}

				var widgets_per_sec_size = self.widgets_per_sec_.size();
				for (var i = 0; i < widgets_per_sec_size; ++i) {
					var widget = self.widgets_per_sec_[i];
					if (widget.contains(pos_x, pos_y)) {
						return widget.open();
					}
				}
			}

			return false;
		}

		function onLayout(_dc as Graphics.Dc) as Void {
			var layout = new Layout(
				_dc,
				!self.top_outer_.isEmpty(),
				0 < self.top_middle_.size(),
				!self.top_inner_.isEmpty(),
				!self.bottom_inner_date_.isEmpty() or
					!self.bottom_inner_am_pm_.isEmpty(),
				0 < self.bottom_middle_.size(),
				!self.bottom_outer_.isEmpty()
			);

			self.bitmap_ = self.createBitmap_(
				layout.screen_size_x,
				layout.screen_size_y
			);

			if (self.bitmap_ != null) {
				System.println("Using buffered bitmap");
			}

			self.invalidate_();

			// ---- top outer ----

			self.LayoutWidget_(_dc, self.top_outer_, layout.top_outer);

			// ---- top middle ----

			self.FitWidgetsInBox_(_dc, self.top_middle_, layout.top_middle);

			// ---- top inner ----

			self.LayoutWidget_(_dc, self.top_inner_, layout.top_inner);

			// ---- main ----

			// -- left --

			self.LayoutWidget_(_dc, self.status_, layout.left);

			// -- clock --

			self.LayoutWidget_(_dc, self.clock_, layout.clock);

			// -- right --

			var gauges_size = self.gauges_.size();
			for (var i = 0; i < gauges_size; ++i) {
				self.gauges_[i].resize(
					_dc,
					layout.right.size_x,
					layout.right.size_y
				);
			}
			self.DistributeWidgetsInBox_(self.gauges_, layout.right);

			// ---- bottom inner ----

			self.layoutBottomInner_(_dc, layout.bottom_inner);

			// ---- bottom middle ----

			self.FitWidgetsInBox_(
				_dc,
				self.bottom_middle_,
				layout.bottom_middle
			);

			// ---- bottom outer ----

			self.LayoutWidget_(_dc, self.bottom_outer_, layout.bottom_outer);

			// ---- footer ----

			self.needs_reposition_ = false;
		}

		function onPartialUpdate(_dc as Graphics.Dc) as Void {
			// ---- header ----

			if (!self.is_visible_) {
				return;
			}
			if (self.is_night_mode_) {
				return;
			}

			Runtime.refreshClock();

			self.seconds_.refresh(_dc);
			if (self.update_mode_ != UPDATE_MODE_LIMITED_POWER) {
				self.seconds_.update(_dc);
			} else {
				self.seconds_.updateMinimal(_dc);
			}
		}

		function onUpdate(_dc as Graphics.Dc) as Void {
			if (!self.is_visible_) {
				return;
			}

			if (self.needs_reposition_) {
				self.onLayout(_dc);
			}

			Runtime.refreshClock();

			if (self.last_refresh_min_ != Runtime.day_minute) {
				Runtime.refreshCalendar();
				var is_night_mode = self.isNightMode_();

				if (self.is_night_mode_ != is_night_mode) {
					self.is_night_mode_ = is_night_mode;

					self.invalidate_();
				}
			}

			if (self.is_night_mode_) {
				self.updateMinimal_(_dc);
			} else {
				self.updateNormal_(_dc);
			}
		}

		hidden function updateMinimal_(_dc as Graphics.Dc) as Void {
			Render.clear(_dc);

			// The minimal face has little reusable content, so a full-screen
			// bitmap copy costs more than rendering it directly.

			if (self.last_refresh_min_ != Runtime.day_minute) {
				self.last_refresh_min_ = Runtime.day_minute;

				self.clock_.refresh(_dc);
			}
			self.status_.refresh(_dc);
			self.refreshWidgets_(_dc, self.batteries_);

			self.clock_.renderMinimal(_dc);
			self.status_.renderMinimal(_dc);

			var batteries_size = self.batteries_.size();
			for (var i = 0; i < batteries_size; ++i) {
				self.batteries_[i].renderMinimal(_dc);
			}
		}

		hidden function updateNormal_(_dc as Graphics.Dc) as Void {
			WeatherProvider.refresh();

			if (self.last_refresh_hour_ != Runtime.clock.hour) {
				self.last_refresh_hour_ = Runtime.clock.hour;
				self.refreshWidgets_(_dc, self.widgets_per_hour_);
			}
			if (self.last_refresh_min_ != Runtime.day_minute) {
				self.last_refresh_min_ = Runtime.day_minute;
				self.refreshWidgets_(_dc, self.widgets_per_min_);
			}
			self.refreshWidgets_(_dc, self.widgets_per_sec_);

			self.refreshChangedWidgets_(_dc, self.widgets_per_hour_);
			self.refreshChangedWidgets_(_dc, self.widgets_per_min_);
			self.refreshChangedWidgets_(_dc, self.widgets_per_sec_);

			if (self.bitmap_ != null) {
				var dc = self.bitmap_.getDc();
				dc.clearClip();

				self.updateWidgets_(dc, self.widgets_per_hour_);
				self.updateWidgets_(dc, self.widgets_per_min_);
				self.updateWidgets_(dc, self.widgets_per_sec_);

				_dc.clearClip();
				_dc.drawBitmap(0, 0, self.bitmap_ as Graphics.BufferedBitmap);
			} else {
				Render.clear(_dc);

				self.renderWidgets_(_dc, self.widgets_per_hour_);
				self.renderWidgets_(_dc, self.widgets_per_min_);
				self.renderWidgets_(_dc, self.widgets_per_sec_);
			}

			self.seconds_.refresh(_dc);
			if (self.update_mode_ != UPDATE_MODE_LIMITED_POWER) {
				self.seconds_.render(_dc);
			} else {
				self.seconds_.renderMinimal(_dc);
			}
		}

		hidden function rebuildWidgets_(_properties as Properties) as Void {
			// ---- header ----

			self.last_refresh_min_ = -1;
			self.last_refresh_hour_ = -1;

			self.needs_reposition_ = true;
			self.bitmap_ = null;

			self.batteries_ = [];

			self.widgets_per_hour_ = [];
			self.widgets_per_min_ = [];
			self.widgets_per_sec_ = [];

			// ---- top outer ----

			self.top_outer_ = Widgets.get(_properties.top_outer, Render.TOP);
			if (self.IsBatteryData_(_properties.top_outer.data)) {
				self.batteries_.add(self.top_outer_ as Widgets.Battery);
			}
			self.addWidget_(self.top_outer_);

			// ---- top middle ----

			self.top_middle_ = self.CreateMetricWidgets_(
				_properties.top_middle,
				Properties.ICON
			);
			self.addWidgets_(self.top_middle_);

			// ---- top inner ----

			self.top_inner_ = new Widgets.Weather();
			self.addWidget_(self.top_inner_);

			// ---- main ----

			self.status_ = new Widgets.Status(_properties.status);
			self.addWidget_(self.status_);

			self.clock_ = new Widgets.Clock(_properties.clock);
			self.addWidget_(self.clock_);

			self.gauges_ = [];
			var gauges_size = _properties.gauges.size();
			for (var i = 0; i < gauges_size; ++i) {
				var properties = _properties.gauges[i];

				var data = Data.get(properties.data);
				if (data == null) {
					continue;
				}

				self.gauges_.add(new Widgets.Gauge(properties, data));
			}
			self.addWidgets_(self.gauges_);

			// ---- bottom inner ----

			self.bottom_inner_date_ = new Widgets.Date();
			self.addWidget_(self.bottom_inner_date_);
			if (Data.Units.is_24_hour) {
				self.bottom_inner_am_pm_ = Widgets.Base.None();
			} else {
				self.bottom_inner_am_pm_ = new Widgets.AmPm();
				self.addWidget_(self.bottom_inner_am_pm_);
			}

			self.seconds_ = new Widgets.Seconds();

			// ---- bottom middle ----

			self.bottom_middle_ = self.CreateMetricWidgets_(
				_properties.bottom_middle,
				Properties.GAUGE
			);
			self.addWidgets_(self.bottom_middle_);

			// ---- bottom outer ----

			self.bottom_outer_ = Widgets.get(
				_properties.bottom_outer,
				Render.BOTTOM
			);
			if (self.IsBatteryData_(_properties.bottom_outer.data)) {
				self.batteries_.add(self.bottom_outer_ as Widgets.Battery);
			}
			self.addWidget_(self.bottom_outer_);
		}

		hidden function isNightMode_() as Lang.Boolean {
			var user_profile = UserProfile.getProfile();
			if (user_profile.sleepTime == null) {
				return false;
			}
			if (user_profile.wakeTime == null) {
				return false;
			}

			var sleep_time = user_profile.sleepTime as Time.Duration;
			var wake_time = user_profile.wakeTime as Time.Duration;

			var now = Runtime.now;
			var midnight = Runtime.today;
			var now_time = now.subtract(midnight) as Time.Duration;

			if (wake_time.lessThan(sleep_time)) {
				// wake < sleep
				return (
					!now_time.lessThan(sleep_time) or // sleep <= now
					now_time.lessThan(wake_time) // now < wake
				);
			}
			return (
				!now_time.lessThan(sleep_time) and // sleep <= now
				now_time.lessThan(wake_time) // now < wake
			);
		}

		hidden function layoutBottomInner_(
			_dc as Graphics.Dc,
			_box as Box
		) as Void {
			var date_size_x = Render.TextWidth(
				_dc,
				Lang.format("$1$ 00 $2$", [
					Resources.getDayOfWeek(1),
					Resources.getMonth(1),
				]),
				Render.SIZE_REGULAR
			);

			self.bottom_inner_date_.pos_x = _box.pos_x;
			self.bottom_inner_date_.pos_y = _box.pos_y;
			self.bottom_inner_date_.resize(_dc, date_size_x, _box.size_y);

			var seconds_size_x = Render.TextWidth(
				_dc,
				"00",
				Render.SIZE_REGULAR
			);
			self.seconds_.pos_x = _box.end_x - seconds_size_x;
			self.seconds_.pos_y = _box.pos_y;
			self.seconds_.resize(_dc, seconds_size_x, _box.size_y);

			if (Data.Units.is_24_hour) {
				return;
			}

			var left_space_x = _box.size_x - date_size_x - seconds_size_x;
			var am_pm_size_x =
				Render.IconsWidth(
					_dc,
					Fonts.ICON_AM_PM_BEGIN + Fonts.ICON_AM_PM_END
				) +
				Render.TextWidth(_dc, "am", Render.SIZE_SMALL) +
				2 * Render.SPACING;
			var am_pm_pos_x =
				_box.pos_x + date_size_x + (left_space_x - am_pm_size_x) / 2;
			var am_pm_is_small = left_space_x < am_pm_size_x;

			if (am_pm_is_small) {
				var am_pm_icon_size_x = Render.IconsWidth(_dc, Fonts.ICON_DAWN);

				am_pm_size_x =
					left_space_x < am_pm_icon_size_x ? 0 : am_pm_icon_size_x;

				if (date_size_x <= seconds_size_x) {
					am_pm_pos_x = _box.pos_x + date_size_x;
				} else {
					am_pm_pos_x = _box.end_x - seconds_size_x - am_pm_size_x;
				}
			}

			self.bottom_inner_am_pm_.pos_x = am_pm_pos_x;
			self.bottom_inner_am_pm_.pos_y = _box.pos_y;
			self.bottom_inner_am_pm_.resize(_dc, am_pm_size_x, _box.size_y);
		}

		hidden function addWidget_(_widget as Widgets.Base) as Void {
			switch (_widget.refresh_rate) {
				case RefreshRate.NONE:
					break;

				case RefreshRate.HOUR:
					self.widgets_per_hour_.add(_widget);
					break;

				case RefreshRate.MIN:
					self.widgets_per_min_.add(_widget);
					break;

				case RefreshRate.SEC:
					self.widgets_per_sec_.add(_widget);
					break;

				default:
					System.println("Unsupported refresh rate");
			}
		}

		hidden function addWidgets_(_widgets as Bases) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				self.addWidget_(_widgets[i]);
			}
		}

		(:memory_low)
		hidden function createBitmap_(
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Graphics.BufferedBitmap? {
			return null;
		}

		(:memory_not_low)
		hidden function createBitmap_(
			_size_x as Lang.Number,
			_size_y as Lang.Number
		) as Graphics.BufferedBitmap? {
			var options = { :width => _size_x, :height => _size_y };

			// 40Kb is empirically tested and seems to be working
			if (System.getSystemStats().freeMemory <= 40 * 1024) {
				return null;
			}

			try {
				if (Graphics has :createBufferedBitmap) {
					return (
						Graphics.createBufferedBitmap(options).get() as
						Graphics.BufferedBitmap
					);
				}
				if (Graphics has :BufferedBitmap) {
					return new Graphics.BufferedBitmap(options);
				}
			} catch (ex) {}

			return null;
		}

		hidden static function CreateMetricWidgets_(
			_properties as Lang.Array<Properties.Metric>,
			_style as Lang.Number
		) as Bases {
			var widgets = [];
			var properties_size = _properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var properties = _properties[i];

				var data = Data.get(properties.data);
				if (data == null) {
					continue;
				}

				widgets.add(new Widgets.Metric(properties, _style, data));
			}
			return widgets;
		}

		hidden static function IsBatteryData_(
			_data as Lang.Number
		) as Lang.Boolean {
			return (
				_data == Properties.DATA_BATTERY_DAYS_REMAINING or
				_data == Properties.DATA_BATTERY_ICON or
				_data == Properties.DATA_BATTERY_PERCENTAGE
			);
		}

		hidden static function LayoutWidget_(
			_dc as Graphics.Dc,
			_widget as Widgets.Base,
			_box as Box
		) as Void {
			_widget.pos_x = _box.pos_x;
			_widget.pos_y = _box.pos_y;
			_widget.resize(_dc, _box.size_x, _box.size_y);
		}

		hidden static function FitWidgetsInBox_(
			_dc as Graphics.Dc,
			_widgets as Bases,
			_box as Box
		) as Void {
			var widgets_size = _widgets.size();
			if (widgets_size == 0) {
				return;
			}

			if (
				self.TryFitWidgets_(
					_dc,
					_widgets,
					_box,
					_box.size_x,
					Render.SIZE_REGULAR
				) or
				self.TryFitWidgets_(
					_dc,
					_widgets,
					_box,
					_box.size_x,
					Render.SIZE_SMALL
				) or
				self.TryFitWidgets_(
					_dc,
					_widgets,
					_box,
					self.EvenItemWidth_(widgets_size, _box.size_x),
					Render.SIZE_SMALL
				)
			) {
			}
			self.DistributeWidgetsInBox_(_widgets, _box);
		}

		hidden static function TryFitWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases,
			_box as Box,
			_size_x as Lang.Number,
			_is_small as Lang.Boolean
		) as Lang.Boolean {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				var widget = _widgets[i];

				widget.is_small = _is_small;
				widget.resize(_dc, _size_x, _box.size_y);
			}

			return self.DistributedWidth_(_widgets) <= _box.size_x;
		}

		hidden function refreshWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases
		) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				_widgets[i].refresh(_dc);
			}
		}

		hidden function refreshChangedWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases
		) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				var widget = _widgets[i];
				if (widget.needsRefresh()) {
					widget.refresh(_dc);
				}
			}
		}

		hidden function renderWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases
		) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				_widgets[i].render(_dc);
			}
		}

		hidden function updateWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases
		) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				_widgets[i].update(_dc);
			}
		}

		hidden function invalidateWidgets_(_widgets as Bases) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				_widgets[i].invalidate();
			}
		}

		hidden function invalidate_() as Void {
			self.last_refresh_min_ = -1;
			self.last_refresh_hour_ = -1;

			self.invalidateWidgets_(self.widgets_per_hour_);
			self.invalidateWidgets_(self.widgets_per_min_);
			self.invalidateWidgets_(self.widgets_per_sec_);

			if (self.bitmap_ != null) {
				Render.clear(self.bitmap_.getDc());
			}
		}

		hidden static function DistributeWidgetsInBox_(
			_widgets as Bases,
			_box as Box
		) as Void {
			var widgets_size = _widgets.size();
			if (widgets_size == 0) {
				return;
			}

			var occupied_size_x = self.OccupiedWidth_(_widgets);
			var gap_x = (_box.size_x - occupied_size_x) / widgets_size;
			if (gap_x < 0) {
				gap_x = 0;
			}
			var pos_x = _box.pos_x + gap_x / 2;
			var pos_y = _box.pos_y;
			for (var i = 0; i < widgets_size; ++i) {
				var widget = _widgets[i];

				widget.pos_x = pos_x;
				widget.pos_y = pos_y;

				pos_x += gap_x + widget.size_x;
			}
		}

		hidden static function OccupiedWidth_(
			_widgets as Bases
		) as Lang.Number {
			var occupied_size_x = 0;
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				occupied_size_x += _widgets[i].size_x;
			}

			return occupied_size_x;
		}

		hidden static function DistributedWidth_(
			_widgets as Bases
		) as Lang.Number {
			return (
				self.OccupiedWidth_(_widgets) + _widgets.size() * Render.SPACING
			);
		}

		hidden static function EvenItemWidth_(
			_items_size as Lang.Number,
			_size_x as Lang.Number
		) as Lang.Number {
			var size_x = (_size_x - _items_size * Render.SPACING) / _items_size;

			return size_x < 0 ? 0 : size_x;
		}
	}
} // module Phase0
