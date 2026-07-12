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
		hidden var battery_ as Widgets.Battery? = null;

		hidden var top_outer_ as Widgets.Base = new Widgets.Base(
			Complications.COMPLICATION_TYPE_INVALID
		);
		hidden var top_middle_base_ as Metrics = [];
		hidden var top_middle_alt_ as Metrics = [];
		hidden var top_inner_ as Widgets.Base = new Widgets.Base(
			Complications.COMPLICATION_TYPE_INVALID
		);

		hidden var bottom_middle_base_ as Metrics = [];
		hidden var bottom_middle_alt_ as Metrics = [];
		hidden var bottom_inner_date_ as Widgets.Date = new Widgets.Date();
		hidden var bottom_inner_am_pm_ as Widgets.AmPm = new Widgets.AmPm();
		hidden var bottom_outer_ as Widgets.Base = new Widgets.Base(
			Complications.COMPLICATION_TYPE_INVALID
		);

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

			self.top_outer_.pos_x = layout.outer.pos_x;
			self.top_outer_.pos_y = layout.outer.pos_y;
			self.top_outer_.size_x = layout.outer.size_x;
			self.top_outer_.size_y = layout.outer.size_y;

			// ---- top middle ----

			self.repositionMetrics_(_dc, self.top_middle_base_, layout.middle);
			self.repositionMetrics_(_dc, self.top_middle_alt_, layout.middle);

			// ---- top inner ----

			self.top_inner_.pos_x = layout.inner.center_x;
			self.top_inner_.pos_y = layout.inner.center_y;
			self.top_inner_.size_x = layout.inner.radius_x;
			self.top_inner_.size_y = layout.inner.radius_y;

			// ---- main ----

			// -- left --

			self.status_.pos_x = layout.left.center_x;
			self.status_.pos_y = layout.left.center_y;

			// -- clock --

			self.clock_.is_small = layout.clock.is_small;
			self.clock_.pos_x = layout.clock.pos_x;
			self.clock_.pos_y = layout.clock.pos_y;
			self.clock_.size_x = layout.clock.size_x;
			self.clock_.size_y = layout.clock.size_y;

			// -- right --

			var layout_right = layout.rightBox(layout.left);
			var gauges_size = self.gauges_.size();
			for (var i = 0; i < gauges_size; ++i) {
				self.gauges_[i].size_y = layout_right.size_y;
			}
			self.repositionWidgets_(self.gauges_ as Bases, layout_right);

			// ---- bottom inner ----

			var bottom_inner = layout.bottomBox(layout.inner);

			var date_size_x = Render.TextWidth(
				_dc,
				"ABC 00 XYZ",
				layout.inner.is_small
			);
			self.bottom_inner_date_.is_small = layout.inner.is_small;
			self.bottom_inner_date_.pos_x = bottom_inner.pos_x;
			self.bottom_inner_date_.pos_y = bottom_inner.pos_y;
			self.bottom_inner_date_.size_x = date_size_x;
			self.bottom_inner_date_.size_y = bottom_inner.size_y;

			var seconds_size_x = Render.TextWidth(
				_dc,
				"00",
				bottom_inner.is_small
			);
			self.seconds_.is_small = layout.inner.is_small;
			self.seconds_.pos_x = bottom_inner.end_x - seconds_size_x;
			self.seconds_.pos_y = bottom_inner.pos_y;
			self.seconds_.size_x = seconds_size_x;
			self.seconds_.size_y = bottom_inner.size_y;

			if (!Data.Units.is_24_hour) {
				var left_space_x =
					bottom_inner.size_x - date_size_x - seconds_size_x;
				var am_pm_size_x =
					Render.IconsWidth(_dc, Fonts.ICON_AM_PM_BEGIN) +
					Render.TextWidth(_dc, "am", true) +
					Render.IconsWidth(_dc, Fonts.ICON_AM_PM_END);
				var am_pm_pos_x =
					bottom_inner.pos_x +
					date_size_x +
					(left_space_x - am_pm_size_x) / 2;

				if (left_space_x < am_pm_size_x) {
					var am_pm_icon_size_x = Render.IconsWidth(
						_dc,
						Fonts.ICON_DAWN
					);

					bottom_inner.is_small = true;
					am_pm_size_x =
						left_space_x <= 0
							? 0
							: left_space_x < am_pm_icon_size_x
								? left_space_x
								: am_pm_icon_size_x;

					if (date_size_x <= seconds_size_x) {
						am_pm_pos_x = bottom_inner.pos_x + date_size_x;
					} else {
						am_pm_pos_x =
							bottom_inner.end_x - seconds_size_x - am_pm_size_x;
					}
				}

				self.bottom_inner_am_pm_.is_small = bottom_inner.is_small;
				self.bottom_inner_am_pm_.pos_x = am_pm_pos_x + am_pm_size_x / 2;
				self.bottom_inner_am_pm_.pos_y = bottom_inner.center_y;
				self.bottom_inner_am_pm_.size_x = am_pm_size_x / 2;
				self.bottom_inner_am_pm_.size_y = bottom_inner.radius_y;
			}

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
			self.bottom_outer_.pos_x = bottom_outer.pos_x;
			self.bottom_outer_.pos_y = bottom_outer.pos_y;
			self.bottom_outer_.size_x = bottom_outer.size_x;
			self.bottom_outer_.size_y = bottom_outer.size_y;

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
				self.seconds_.size_x,
				self.seconds_.size_y
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
				if (self.battery_ != null) {
					self.battery_.refresh(_dc);
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
			if (self.battery_ != null) {
				self.battery_.renderMinimal(_dc);
			}
		}

		hidden function refreshProperties_() as Void {
			// ---- header ----

			self.last_refresh_min_ = -1;
			self.last_refresh_hour_ = -1;

			self.needs_reposition_ = true;

			self.widgets_per_min_ = [];
			self.widgets_per_hour_ = [];
			self.battery_ = null;

			// ---- top outer ----

			self.top_outer_ = Widgets.get(Properties.top_outer, Render.TOP);
			if (
				Properties.top_outer.data ==
					Properties.BATTERY_DAYS_REMAINING or
				Properties.top_outer.data == Properties.BATTERY_ICON or
				Properties.top_outer.data == Properties.BATTERY_PERCENTAGE
			) {
				self.battery_ = self.top_outer_ as Widgets.Battery;
				self.widgets_per_min_.add(self.top_outer_);
			} else {
				self.widgets_per_hour_.add(self.top_outer_);
			}

			// ---- top middle ----

			self.top_middle_base_ = self.propertiesToMetrics_(
				Properties.top_middle
			);
			self.top_middle_alt_ = self.propertiesToMetrics_(
				Properties.top_middle_alt
			);

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
				Properties.bottom_middle
			);
			self.bottom_middle_alt_ = self.propertiesToMetrics_(
				Properties.bottom_middle_alt
			);

			// ---- bottom outer ----

			self.bottom_outer_ = Widgets.get(
				Properties.bottom_outer,
				Render.BOTTOM
			);
			if (
				Properties.bottom_outer.data ==
					Properties.BATTERY_DAYS_REMAINING or
				Properties.bottom_outer.data == Properties.BATTERY_ICON or
				Properties.bottom_outer.data == Properties.BATTERY_PERCENTAGE
			) {
				self.battery_ = self.bottom_outer_ as Widgets.Battery;
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
			_properties as Lang.Array<Properties.Metric>
		) as Metrics {
			var metrics = [];
			var properties_size = _properties.size();
			for (var i = 0; i < properties_size; ++i) {
				var properties = _properties[i];

				var data = Data.get(properties.data);
				if (data == null) {
					continue;
				}

				metrics.add(new Widgets.Metric(properties, data));
			}
			return metrics;
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

			var metrics_size_regular = 0;
			for (var i = 0; i < metrics_size; ++i) {
				var metric = _metrics[i];

				metrics_size_regular += Widgets.Metric.Width(
					_dc,
					metric.properties.width,
					Render.SIZE_REGULAR,
					metric.properties.icon,
					metric.properties.gauge,
					metric.properties.padding
				);
			}
			var metric_is_small =
				_box.is_small || _box.size_x < metrics_size_regular;

			for (var i = 0; i < metrics_size; ++i) {
				var metric = _metrics[i];
				metric.is_small = metric_is_small;
				metric.resize(_dc);
			}

			self.repositionWidgets_(_metrics as Bases, _box);
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

			var occupied_size_x = 0;
			for (var i = 0; i < widgets_size; ++i) {
				occupied_size_x += _widgets[i].size_x;
			}

			var spacing = (_box.size_x - occupied_size_x) / widgets_size;

			var pos_x = _box.pos_x + spacing / 2;
			var pos_y = _box.pos_y;
			for (var i = 0; i < widgets_size; ++i) {
				var widget = _widgets[i];

				widget.pos_x = pos_x;
				widget.pos_y = pos_y;

				pos_x += spacing + widget.size_x;
			}
		}
	}
} // module Phase0
