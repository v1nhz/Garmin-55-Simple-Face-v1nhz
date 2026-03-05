using Toybox.WatchUi;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Graphics;
using Toybox.Weather;
using Toybox.Application;


class simplefaceView extends WatchUi.WatchFace {

    var isAwake;

    // bitmaps
    var heartBmp;
    var footIcon;
    var hotIcon;
    var moonWhite16;
    var locationWhite16;

    // cached labels
    var lblDate;
    var lblLunarDate;
    var lblTime;
    var lblBattery;
    var lblHR;
    var lblSteps;
    var lblDistance;
    var lblCalories;
    var lblTitle;

    // txt value
    var txtDate = "";
    var txtLunarDate = "";
    var txtTime = "";
    var txtBattery = "";
    var txtHR = "";
    var txtSteps = "";
    var txtDistance = "";
    var txtCalories = "";
    var txtTitle = "";

    var lunarConverter;
    var cachedLunar;
    var cachedDay = -1;

    var cachedWeather;
    var cachedWeatherMinute = -1;

    function initialize() {
        WatchFace.initialize();
        isAwake = true;

        lunarConverter = new LunarConverter();
        heartBmp = WatchUi.loadResource(Rez.Drawables.HeartRedIcon);
        footIcon = WatchUi.loadResource(Rez.Drawables.FootIcon);
        hotIcon  = WatchUi.loadResource(Rez.Drawables.HotIcon);
        moonWhite16 = WatchUi.loadResource(Rez.Drawables.MoonWhite16);
        locationWhite16 = WatchUi.loadResource(Rez.Drawables.LocationWhite16);
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        // Cache the label once
        lblDate     = View.findDrawableById("Date");
        lblLunarDate = View.findDrawableById("LunarDate");
        lblTime     = View.findDrawableById("HoursAndMinutes");
        lblBattery  = View.findDrawableById("Battery");
        lblHR       = View.findDrawableById("HeartRate");
        lblSteps    = View.findDrawableById("Steps");
        lblCalories = View.findDrawableById("Calories");
        lblTitle    = View.findDrawableById("Title");
    }

    function onEnterSleep() {
        isAwake = false;
    }

    function onExitSleep() {
        isAwake = true;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        // init
        var now  = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var sys  = System.getSystemStats();
        var info = ActivityMonitor.getInfo();
        var act = Activity.getActivityInfo();

        // watchname
        var watchName = Application.Properties.getValue("watchName");
        var watchNameColor = Application.Properties.getValue("watchNameColor");
        txtTitle = watchName != null ? watchName : "Garmin";
        lblTitle.setColor(watchNameColor.toNumber());

        // time hour:minutes
        txtTime = date.hour.format("%02d") + ":" + date.min.format("%02d");
        
        // pin
        txtBattery = sys.battery.format("%d") + "%";

        // heart rate
        txtHR = act != null && act.currentHeartRate != null ? act.currentHeartRate.format("%d") : "--";

       // distance
       txtDistance = info.distance != null ? formatKmFromCm(info.distance) : "--";

       // calories
       txtCalories = info.calories != null ? info.calories.format("%d") : "--";

        // solar date & lunar date
        if (date.day != cachedDay) {
            cachedDay = date.day;

            var solar = new Solar();
            solar.solarYear  = date.year;
            solar.solarMonth = date.month;
            solar.solarDay   = date.day;
            cachedLunar = lunarConverter.SolarToLunar(solar);

            var lMonthStr = cachedLunar.lunarMonth.format("%d");
            var lDayStr   = cachedLunar.lunarDay.format("%d");
            var countlMonthStr = lMonthStr.length();
            txtLunarDate = lDayStr + "-" + (countlMonthStr == 1 ? "0" + lMonthStr : lMonthStr);
            txtDate = formatFullDate(date);
        }
        
        // set value
        setValueToLabel();

        WatchFace.onUpdate(dc);
        // ---- ICONS ----
        dc.drawBitmap(75, 183, heartBmp);
        dc.drawBitmap(110, 98, locationWhite16);
        dc.drawBitmap(110, 122, footIcon);
        dc.drawBitmap(110, 146, hotIcon);
        dc.drawBitmap(40, 122, moonWhite16);
        drawBatteryIcon(dc, sys.battery);
    }

    
    function setValueToLabel() {
        lblDate.setText(txtDate);
        lblBattery.setText("99%");
        lblTime.setText(txtTime);
        lblLunarDate.setText(txtLunarDate);
        lblHR.setText(txtHR);
        lblSteps.setText(txtDistance);
        lblCalories.setText(txtCalories);
        lblTitle.setText(txtTitle);
    }

    // --- HELPER FUNCTIONS ---
    // convert cm to km
    function formatKmFromCm(cm) {
        if (cm == null) {
            return "--";
        }
        var km = cm / 100000.0;
        var kmStr = km.format("%.2f");
        var len = kmStr.length();
        // Check ".00"
        if (len >= 3 && kmStr.substring(len - 3, len) == ".00") {
            kmStr = kmStr.substring(0, len - 3);
        }
        // Check trailing "0"
        else if (len >= 1 && kmStr.substring(len - 1, len) == "0") {
            kmStr = kmStr.substring(0, len - 1);
        }
        return kmStr + " km";
    }

    // convert date object to string
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

    // ---DRAW ICON---
    // draw battery icon
    function drawBatteryIcon(dc, battery) {
        var w = 37;
        var h = 20;
        var x = 85;
        var y = 2;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + (h / 4), 2, h / 2);
        // var fillWidth = (w - 4) * battery / 100;
        // if (fillWidth > 0) {
        //     dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_GREEN);
        //     dc.fillRectangle(x + 2, y + 2, fillWidth, h - 4);
        // }
    }
}