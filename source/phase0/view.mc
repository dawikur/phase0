// Copyright (c) 2026 Dawid Kurek <dawikur@gmail.com>

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.UserProfile;
import Toybox.WatchUi;

module Phase0 {
	class View extends WatchUi.WatchFace {
		typedef Bases as Lang.Array<Widgets.Base>;
		typedef Batteries as Lang.Array<Widgets.Battery>;
		typedef Gauges as Lang.Array<Widgets.Gauge>;
		typedef Metrics as Lang.Array<Widgets.Metric>;

		// ---- fields ----

		// -- base --
		hidden var is_base_view_ as Lang.Boolean = true;
		hidden var is_high_power_ as Lang.Boolean = true;
		hidden var is_night_mode_ as Lang.Boolean = false;
		hidden var is_visible_ as Lang.Boolean = false;

		hidden var needs_reposition_ as Lang.Boolean = false;

		// -- refresh --
		hidden var last_refresh_min_ as Lang.Number = -1;
		hidden var last_refresh_hour_ as Lang.Number = -1;

		// -- widgets --
		hidden var status_ as Widgets.Status = new Widgets.Status(
			Properties.status
		);
		hidden var gauges_ as Gauges = [];

		hidden var clock_ as Widgets.Clock = new Widgets.Clock(
			Properties.clock
		);
		hidden var seconds_ as Widgets.Seconds = new Widgets.Seconds();
		hidden var batteries_ as Batteries = [];

		hidden var top_outer_ as Widgets.Base = new Widgets.Base(null);
		hidden var top_middle_base_ as Metrics = [];
		hidden var top_middle_alt_ as Metrics = [];
		hidden var top_inner_ as Widgets.Base = new Widgets.Base(null);

		hidden var bottom_middle_base_ as Metrics = [];
		hidden var bottom_middle_alt_ as Metrics = [];
		hidden var bottom_inner_date_ as Widgets.Date = new Widgets.Date();
		hidden var bottom_inner_am_pm_ as Widgets.AmPm = new Widgets.AmPm();
		hidden var bottom_outer_ as Widgets.Base = new Widgets.Base(null);

		hidden var widgets_per_min_ as Bases = [];
		hidden var widgets_per_hour_ as Bases = [];

		// ---- methods ----

		function initialize() {
			WatchFace.initialize();

			self.refreshProperties_();
		}

		function onShow() as Void {
			self.is_visible_ = true;
		}

		function onHide() as Void {
			self.is_visible_ = false;
		}

		function onEnterSleep() as Void {
			self.is_base_view_ = true;

			WatchUi.requestUpdate();
		}

		function onExitSleep() as Void {
			self.is_base_view_ = true;
			self.is_high_power_ = true;

			WatchUi.requestUpdate();
		}

		function onSettingsChanged() as Void {
			self.refreshProperties_();

			WatchUi.requestUpdate();
		}

		function onPowerBudgetExceeded() as Void {
			self.is_high_power_ = false;
		}

		function onPress(_click_event as WatchUi.ClickEvent) as Lang.Boolean {
			var coordinates = _click_event.getCoordinates();
			var pos_x = coordinates[0];
			var pos_y = coordinates[1];

			if (self.clock_.contains(pos_x, pos_y)) {
				self.is_base_view_ = !self.is_base_view_;
				WatchUi.requestUpdate();

				return true;
			}

			if (!self.is_night_mode_) {
				var widgets_per_min_size = widgets_per_min_.size();
				for (var i = 0; i < widgets_per_min_size; ++i) {
					var widget = widgets_per_min_[i];
					if (widget.contains(pos_x, pos_y)) {
						return widget.open();
					}
				}

				var widgets_per_hour_size = widgets_per_hour_.size();
				for (var i = 0; i < widgets_per_hour_size; ++i) {
					var widget = widgets_per_hour_[i];
					if (widget.contains(pos_x, pos_y)) {
						return widget.open();
					}
				}

				var top_metrics = self.getTopMetrics_();
				var top_metrics_size = top_metrics.size();
				for (var i = 0; i < top_metrics_size; ++i) {
					var metric = top_metrics[i];
					if (metric.contains(pos_x, pos_y)) {
						return metric.open();
					}
				}

				var bottom_metrics = self.getBottomMetrics_();
				var bottom_metrics_size = bottom_metrics.size();
				for (var i = 0; i < bottom_metrics_size; ++i) {
					var metric = bottom_metrics[i];
					if (metric.contains(pos_x, pos_y)) {
						return metric.open();
					}
				}
			}

			return false;
		}

		function onLayout(_dc as Graphics.Dc) as Void {
			var layout = new Layout(_dc);

			// ---- top outer ----

			self.placeWidget_(
				_dc,
				self.top_outer_,
				layout.outer,
				Render.SIZE_REGULAR
			);

			// ---- top middle ----

			self.repositionMetrics_(_dc, self.top_middle_base_, layout.middle);
			self.repositionMetrics_(_dc, self.top_middle_alt_, layout.middle);

			// ---- top inner ----

			self.placeWidget_(
				_dc,
				self.top_inner_,
				layout.inner,
				Render.SIZE_REGULAR
			);

			// ---- main ----

			// -- left --

			self.placeWidget_(
				_dc,
				self.status_,
				layout.left,
				Render.SIZE_REGULAR
			);

			// -- clock --

			self.placeWidget_(
				_dc,
				self.clock_,
				layout.clock,
				Render.SIZE_REGULAR
			);

			// -- right --

			var layout_right = layout.rightBox(layout.left);
			var gauges_size = self.gauges_.size();
			for (var i = 0; i < gauges_size; ++i) {
				self.gauges_[i].resize(
					_dc,
					layout_right.size_x,
					layout_right.size_y,
					Render.SIZE_REGULAR
				);
			}
			self.repositionWidgets_(self.gauges_ as Bases, layout_right);

			// ---- bottom inner ----

			var bottom_inner = layout.bottomBox(layout.inner);
			self.layoutBottomInner_(_dc, bottom_inner);

			// ---- bottom middle ----

			var bottom_middle = layout.bottomBox(layout.middle);
			self.repositionMetrics_(
				_dc,
				self.bottom_middle_base_,
				bottom_middle
			);
			self.repositionMetrics_(
				_dc,
				self.bottom_middle_alt_,
				bottom_middle
			);

			// ---- bottom outer ----

			var bottom_outer = layout.bottomBox(layout.outer);
			self.placeWidget_(
				_dc,
				self.bottom_outer_,
				bottom_outer,
				Render.SIZE_REGULAR
			);

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
			if (!self.is_high_power_) {
				return;
			}

			// ---- refresh ----

			self.seconds_.refresh(_dc);

			// ---- render ----

			_dc.setClip(
				self.seconds_.pos_x,
				self.seconds_.pos_y,
				self.seconds_.size_x + 2,
				self.seconds_.size_y + 2
			);

			_dc.setColor(
				Properties.general.background,
				Properties.general.background
			);
			_dc.clear();

			self.seconds_.render(_dc);
		}

		function onUpdate(_dc as Graphics.Dc) as Void {
			if (!self.is_visible_) {
				return;
			}

			if (self.needs_reposition_) {
				self.onLayout(_dc);
			}

			var clock = System.getClockTime();

			if (self.last_refresh_min_ != clock.min) {
				self.is_night_mode_ = self.isNightMode_();
			}

			if (self.is_night_mode_) {
				self.updateMinimal_(_dc, clock);
			} else {
				self.updateNormal_(_dc, clock);
			}
		}

		function updateNormal_(
			_dc as Graphics.Dc,
			_clock as System.ClockTime
		) as Void {
			// ---- refresh ----

			var top_metrics = self.getTopMetrics_();
			var bottom_metrics = self.getBottomMetrics_();

			{
				self.status_.refresh(_dc);
				self.seconds_.refresh(_dc);

				self.refreshWidgets_(_dc, top_metrics as Bases);
				self.refreshWidgets_(_dc, bottom_metrics as Bases);
			}

			if (self.last_refresh_min_ != _clock.min) {
				self.last_refresh_min_ = _clock.min;

				self.clock_.refresh(_dc);

				self.refreshWidgets_(_dc, self.widgets_per_min_);
			}
			if (self.last_refresh_hour_ != _clock.hour) {
				self.last_refresh_hour_ = _clock.hour;

				self.refreshWidgets_(_dc, self.widgets_per_hour_);
			}

			// ---- render ----

			_dc.clearClip();

			_dc.setColor(
				Properties.general.background,
				Properties.general.background
			);
			_dc.clear();

			self.clock_.render(_dc);
			self.status_.render(_dc);

			if (self.is_high_power_) {
				self.seconds_.render(_dc);
			} else {
				self.seconds_.renderMinimal(_dc);
			}

			self.renderWidgets_(_dc, top_metrics as Bases);
			self.renderWidgets_(_dc, bottom_metrics as Bases);
			self.renderWidgets_(_dc, self.widgets_per_min_);
			self.renderWidgets_(_dc, self.widgets_per_hour_);
		}

		function updateMinimal_(
			_dc as Graphics.Dc,
			_clock as System.ClockTime
		) as Void {
			// ---- refresh ----

			{
				self.status_.refresh(_dc);
			}

			if (self.last_refresh_min_ != _clock.min) {
				self.last_refresh_min_ = _clock.min;

				self.clock_.refresh(_dc);
				var refresh_battery_size = self.batteries_.size();
				for (var i = 0; i < refresh_battery_size; ++i) {
					self.batteries_[i].refresh(_dc);
				}
			}

			// ---- render ----

			_dc.clearClip();
			_dc.setColor(
				Properties.general.background,
				Properties.general.background
			);
			_dc.clear();

			self.clock_.renderMinimal(_dc);
			self.status_.renderMinimal(_dc);
			var render_battery_size = self.batteries_.size();
			for (var j = 0; j < render_battery_size; ++j) {
				self.batteries_[j].renderMinimal(_dc);
			}
		}

		hidden function refreshProperties_() as Void {
			// ---- header ----

			self.last_refresh_min_ = -1;
			self.last_refresh_hour_ = -1;

			self.needs_reposition_ = true;

			self.widgets_per_min_ = [];
			self.widgets_per_hour_ = [];
			self.batteries_ = [];

			// ---- top outer ----

			self.top_outer_ = Widgets.get(Properties.top_outer, Render.TOP);
			if (self.isBatteryData_(Properties.top_outer.data)) {
				self.batteries_.add(self.top_outer_ as Widgets.Battery);
				self.widgets_per_min_.add(self.top_outer_);
			} else {
				self.widgets_per_hour_.add(self.top_outer_);
			}

			// ---- top middle ----

			self.top_middle_base_ = self.propertiesToMetrics_(
				Properties.top_middle,
				Properties.ICON
			);
			if (Properties has :top_middle_alt and (Properties has :ICON)) {
				self.top_middle_alt_ = self.propertiesToMetrics_(
					Properties.top_middle_alt as Lang.Array<Properties.Metric>,
					Properties.ICON as Lang.Number
				);
			}

			// ---- top inner ----

			self.top_inner_ = new Widgets.Weather();
			self.widgets_per_min_.add(self.top_inner_);

			// ---- main ----

			self.status_ = new Widgets.Status(Properties.status);

			self.gauges_ = [];
			var gauges_size = Properties.gauges.size();
			for (var i = 0; i < gauges_size; ++i) {
				var properties = Properties.gauges[i];

				var data = Data.get(properties.data);
				if (data == null) {
					continue;
				}

				self.gauges_.add(new Widgets.Gauge(properties, data));
			}
			self.widgets_per_min_.addAll(self.gauges_ as Bases);

			// ---- bottom inner ----

			self.bottom_inner_date_ = new Widgets.Date();
			self.widgets_per_hour_.add(self.bottom_inner_date_);
			if (!Data.Units.is_24_hour) {
				self.bottom_inner_am_pm_ = new Widgets.AmPm();
				self.widgets_per_hour_.add(self.bottom_inner_am_pm_);
			}

			// ---- bottom middle ----

			self.bottom_middle_base_ = self.propertiesToMetrics_(
				Properties.bottom_middle,
				Properties.GAUGE
			);
			if (Properties has :bottom_middle_alt) {
				self.bottom_middle_alt_ = self.propertiesToMetrics_(
					Properties.bottom_middle_alt as
						Lang.Array<Properties.Metric>,
					Properties.GAUGE
				);
			}

			// ---- bottom outer ----

			self.bottom_outer_ = Widgets.get(
				Properties.bottom_outer,
				Render.BOTTOM
			);
			if (self.isBatteryData_(Properties.bottom_outer.data)) {
				self.batteries_.add(self.bottom_outer_ as Widgets.Battery);
				self.widgets_per_min_.add(self.bottom_outer_);
			} else {
				self.widgets_per_hour_.add(self.bottom_outer_);
			}
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

			var now = Time.now();
			var midnight = Time.today();
			var since_midnight = now.subtract(midnight) as Time.Duration;

			if (sleep_time.greaterThan(wake_time)) {
				return (
					!since_midnight.lessThan(sleep_time) or
					!since_midnight.greaterThan(wake_time)
				);
			}
			return (
				!since_midnight.lessThan(sleep_time) and
				!since_midnight.greaterThan(wake_time)
			);
		}

		hidden function getTopMetrics_() as Metrics {
			if (self.top_middle_alt_.size() == 0) {
				return self.top_middle_base_;
			}

			return self.is_base_view_
				? self.top_middle_base_
				: self.top_middle_alt_;
		}

		hidden function getBottomMetrics_() as Metrics {
			if (self.bottom_middle_alt_.size() == 0) {
				return self.bottom_middle_base_;
			}

			return self.is_base_view_
				? self.bottom_middle_base_
				: self.bottom_middle_alt_;
		}

		hidden static function propertiesToMetrics_(
			_properties as Lang.Array<Properties.Metric>,
			_style as Lang.Number
		) as Metrics {
			var metrics = [];
			var properties_size = _properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var properties = _properties[i];

				var data = Data.get(properties.data);
				if (data == null) {
					continue;
				}

				metrics.add(new Widgets.Metric(properties, _style, data));
			}
			return metrics;
		}

		hidden static function isBatteryData_(
			_data as Lang.Number
		) as Lang.Boolean {
			return (
				_data == Properties.BATTERY_DAYS_REMAINING or
				_data == Properties.BATTERY_ICON or
				_data == Properties.BATTERY_PERCENTAGE
			);
		}

		hidden static function placeWidget_(
			_dc as Graphics.Dc,
			_widget as Widgets.Base,
			_box as Box,
			_is_small as Lang.Boolean
		) as Void {
			_widget.pos_x = _box.pos_x;
			_widget.pos_y = _box.pos_y;
			_widget.resize(_dc, _box.size_x, _box.size_y, _is_small);
		}

		hidden function layoutBottomInner_(
			_dc as Graphics.Dc,
			_box as Box
		) as Void {
			var date_size_x = Render.TextWidth(
				_dc,
				"ABC 00 XYZ",
				Render.SIZE_REGULAR
			);
			self.bottom_inner_date_.pos_x = _box.pos_x;
			self.bottom_inner_date_.pos_y = _box.pos_y;
			self.bottom_inner_date_.resize(
				_dc,
				date_size_x,
				_box.size_y,
				Render.SIZE_REGULAR
			);

			var seconds_size_x = Render.TextWidth(
				_dc,
				"00",
				Render.SIZE_REGULAR
			);
			self.seconds_.pos_x = _box.end_x - seconds_size_x;
			self.seconds_.pos_y = _box.pos_y;
			self.seconds_.resize(
				_dc,
				seconds_size_x,
				_box.size_y,
				Render.SIZE_REGULAR
			);

			if (Data.Units.is_24_hour) {
				return;
			}

			var left_space_x = _box.size_x - date_size_x - seconds_size_x;
			var am_pm_size_x =
				Render.IconsWidth(_dc, Fonts.ICON_AM_PM_BEGIN) +
				Render.TextWidth(_dc, "am", Render.SIZE_SMALL) +
				Render.IconsWidth(_dc, Fonts.ICON_AM_PM_END) +
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
			self.bottom_inner_am_pm_.resize(
				_dc,
				am_pm_size_x,
				_box.size_y,
				am_pm_is_small
			);
		}

		hidden static function repositionMetrics_(
			_dc as Graphics.Dc,
			_metrics as Metrics,
			_box as Box
		) as Void {
			var metrics_size = _metrics.size();
			if (metrics_size == 0) {
				return;
			}

			if (
				self.tryResizeMetrics_(
					_dc,
					_metrics,
					_box,
					_box.size_x,
					Render.SIZE_REGULAR
				)
			) {
				self.repositionWidgets_(_metrics as Bases, _box);

				return;
			}

			if (
				self.tryResizeMetrics_(
					_dc,
					_metrics,
					_box,
					_box.size_x,
					Render.SIZE_SMALL
				)
			) {
				self.repositionWidgets_(_metrics as Bases, _box);

				return;
			}

			self.resizeMetrics_(
				_dc,
				_metrics,
				_box,
				self.evenItemWidth_(metrics_size, _box.size_x),
				Render.SIZE_SMALL
			);
			self.repositionWidgets_(_metrics as Bases, _box);
		}

		hidden static function tryResizeMetrics_(
			_dc as Graphics.Dc,
			_metrics as Metrics,
			_box as Box,
			_size_x as Lang.Number,
			_is_small as Lang.Boolean
		) as Lang.Boolean {
			self.resizeMetrics_(_dc, _metrics, _box, _size_x, _is_small);

			return self.distributedWidth_(_metrics as Bases) <= _box.size_x;
		}

		hidden static function resizeMetrics_(
			_dc as Graphics.Dc,
			_metrics as Metrics,
			_box as Box,
			_size_x as Lang.Number,
			_is_small as Lang.Boolean
		) as Void {
			var metrics_size = _metrics.size();
			for (var i = 0; i < metrics_size; ++i) {
				var metric = _metrics[i];

				metric.resize(_dc, _size_x, _box.size_y, _is_small);
			}
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

		hidden function renderWidgets_(
			_dc as Graphics.Dc,
			_widgets as Bases
		) as Void {
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				_widgets[i].render(_dc);
			}
		}

		hidden static function repositionWidgets_(
			_widgets as Bases,
			_box as Box
		) as Void {
			var widgets_size = _widgets.size();
			if (widgets_size == 0) {
				return;
			}

			var occupied_size_x = self.occupiedWidth_(_widgets);
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

		hidden static function occupiedWidth_(
			_widgets as Bases
		) as Lang.Number {
			var occupied_size_x = 0;
			var widgets_size = _widgets.size();
			for (var i = 0; i < widgets_size; ++i) {
				occupied_size_x += _widgets[i].size_x;
			}

			return occupied_size_x;
		}

		hidden static function distributedWidth_(
			_widgets as Bases
		) as Lang.Number {
			return (
				self.occupiedWidth_(_widgets) + _widgets.size() * Render.SPACING
			);
		}

		hidden static function evenItemWidth_(
			_items_size as Lang.Number,
			_size_x as Lang.Number
		) as Lang.Number {
			var size_x = (_size_x - _items_size * Render.SPACING) / _items_size;

			return size_x < 0 ? 0 : size_x;
		}
	}
} // module Phase0
