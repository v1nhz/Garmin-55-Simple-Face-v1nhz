using Toybox.WatchUi;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Graphics;

class simplefaceView extends WatchUi.WatchFace {

    var isAwake;

    // bitmaps
    var heartBmp;
    var footIcon;
    var hotIcon;
    var moonIcon;

    // cached labels
    var lblDate;
    var lblLunarDate;
    var lblTime;
    var lblDow;
    var lblBattery;
    var lblHR;
    var lblSteps;
    var lblCalories;
    var lblTitle;

    var dowNames = [];

    var lunarConverter;
    var cachedLunar;
    var cachedDay = -1;

    function initialize() {
        WatchFace.initialize();
        isAwake = true;

        heartBmp = WatchUi.loadResource(Rez.Drawables.HeartRedIcon);
        footIcon = WatchUi.loadResource(Rez.Drawables.FootIcon);
        hotIcon  = WatchUi.loadResource(Rez.Drawables.HotIcon);
        moonIcon = WatchUi.loadResource(Rez.Drawables.MoonIcon);

        dowNames.add("Sunday");
        dowNames.add("Monday");
        dowNames.add("Tuesday");
        dowNames.add("Wednesday");
        dowNames.add("Thursday");
        dowNames.add("Friday");
        dowNames.add("Saturday");

        lunarConverter = new LunarConverter();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));

        // Cache the label once
        lblDate     = View.findDrawableById("Date");
        lblLunarDate = View.findDrawableById("LunarDate");
        lblTime     = View.findDrawableById("HoursAndMinutes");
        lblDow      = View.findDrawableById("DayOfTheWeek");
        lblBattery  = View.findDrawableById("Battery");
        lblHR       = View.findDrawableById("HeartRate");
        lblSteps    = View.findDrawableById("Steps");
        lblCalories = View.findDrawableById("Calories");
        lblTitle    = View.findDrawableById("Title");
    }

    function onUpdate(dc) {

        var now  = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var sys  = System.getSystemStats();
        var info = ActivityMonitor.getInfo();

        // ---- TEXT ----
        // if (lblDate != null) {
        //     lblDate.setText(
        //         date.day.format("%02d") + "-" +
        //         date.month.format("%02d")
        //     );
        // }

        // if (lblDow != null) {
        //     var idx = date.day_of_week;
        //     if (idx < 1) { idx = 1; }
        //     if (idx > 7) { idx = 7; }
        //     lblDow.setText(getDowShort(idx-1));
        // }

        // hour:minuties
        if (lblTime != null) {
            lblTime.setText(
                date.hour.format("%02d") + ":" +
                date.min.format("%02d")
            );
        }

        if (lblBattery != null) {
            lblBattery.setText(sys.battery.format("%d") + "%");
        }

        if (lblHR != null) {
            var act = Activity.getActivityInfo();
            if (act != null && act.currentHeartRate != null) {
                lblHR.setText(act.currentHeartRate.format("%d"));
            } else {
                lblHR.setText("--");
            }
        }

        if (info != null) {
            if (lblSteps != null && info.steps != null) {
                lblSteps.setText(info.steps.format("%d"));
            }
            if (lblCalories != null && info.calories != null) {
                lblCalories.setText(info.calories.format("%d"));
            }
        }

        // lunar date
        if (date.day != cachedDay) {
            cachedDay = date.day;
            var solar = new Solar();
            solar.solarYear  = date.year;
            solar.solarMonth = date.month;
            solar.solarDay   = date.day;
            cachedLunar = lunarConverter.SolarToLunar(solar);
            lblLunarDate.setText(cachedLunar.lunarDay + "-" + cachedLunar.lunarMonth);
        }

        // solar date
        var fullDate = formatFullDate(date);
        if (lblDate != null) {
            lblDate.setText(fullDate);
        }

        lblTitle.setText("Vinh ĐZ");

        WatchFace.onUpdate(dc);

        // ---- ICONS ----
        dc.drawBitmap(35, 150, heartBmp);
        dc.drawBitmap(107, 144, footIcon);
        dc.drawBitmap(107, 163, hotIcon);
        dc.drawBitmap(135, 54, moonIcon);

        drawBatteryIcon(dc, sys.battery);
    }

    // draw battery icon
    function drawBatteryIcon(dc, battery) {

        var w = 20;
        var h = 10;
        var x = 75;
        var y = 194;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + (h / 4), 2, h / 2);

        var fillWidth = (w - 4) * battery / 100;

        if (fillWidth > 0) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
            dc.fillRectangle(x + 2, y + 2, fillWidth, h - 4);
        }
    }

    function onEnterSleep() {
        isAwake = false;
    }
    function getDowShort(idx) {
        if (idx == 0) { return "Sun"; }
        if (idx == 1) { return "Mon"; }
        if (idx == 2) { return "Tue"; }
        if (idx == 3) { return "Wed"; }
        if (idx == 4) { return "Thu"; }
        if (idx == 5) { return "Fri"; }
        if (idx == 6) { return "Sat"; }
        return "--";
    }

    function formatFullDate(date) {
        var idx = date.day_of_week - 1;
        var dow;
        if (idx == 0) { dow = "Sun"; }
        else if (idx == 1) { dow = "Mon"; }
        else if (idx == 2) { dow = "Tue"; }
        else if (idx == 3) { dow = "Wed"; }
        else if (idx == 4) { dow = "Thu"; }
        else if (idx == 5) { dow = "Fri"; }
        else if (idx == 6) { dow = "Sat"; }
        else { dow = "--"; }
        return dow + ", "
            + date.day.format("%02d") + "-"
            + date.month.format("%02d") 
            // + "-" + date.year.format("%04d")
            + "";
    }

    function onExitSleep() {
        isAwake = true;
        WatchUi.requestUpdate();
    }
}