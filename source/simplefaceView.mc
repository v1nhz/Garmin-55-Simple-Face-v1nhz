using Toybox.WatchUi;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Graphics;
using Toybox.Application;


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
    var lblBattery;
    var lblHR;
    var lblSteps;
    var lblCalories;
    var lblTitle;

    var lastCalories = "";
    var lastSteps = "";
    var lastBattery = "";
    var lastDate = "";
    var lastLunarDate = "";
    var lastTime = "";
    var lastHR = "";

    // txt value
    var txtDate = "";
    var txtLunarDate = "";
    var txtTime = "";
    var txtHR = "";
    var txtDistance = "";
    var txtCalories = "";
    var txtBattery = "";

    var lunarConverter;
    var cachedLunar;
    var cachedDay = -1;

    var cachedMinute = -1;

    var watchName;
    var watchNameColor;

    var solar;

    var battery = 0;

    function initialize() {
        WatchFace.initialize();

        solar = new Solar();
        lunarConverter = new LunarConverter();

        heartBmp = WatchUi.loadResource(Rez.Drawables.HeartRedIcon);
        footIcon = WatchUi.loadResource(Rez.Drawables.FootIcon);
        hotIcon  = WatchUi.loadResource(Rez.Drawables.HotIcon);
        moonIcon = WatchUi.loadResource(Rez.Drawables.MoonIcon);

        // watchname
        watchName = Application.Properties.getValue("watchName");
        watchNameColor = Application.Properties.getValue("watchNameColor");
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
        // Cache the label once
        lblDate     = View.findDrawableById("Date") as WatchUi.Text;
        lblLunarDate = View.findDrawableById("LunarDate") as WatchUi.Text;
        lblTime     = View.findDrawableById("HoursAndMinutes") as WatchUi.Text;
        lblBattery  = View.findDrawableById("Battery") as WatchUi.Text;
        lblHR       = View.findDrawableById("HeartRate") as WatchUi.Text;
        lblSteps    = View.findDrawableById("Steps") as WatchUi.Text;
        lblCalories = View.findDrawableById("Calories") as WatchUi.Text;
        lblTitle    = View.findDrawableById("Title") as WatchUi.Text;

        lblTitle.setText(watchName);
        lblTitle.setColor(watchNameColor.toNumber());
    }

    function onEnterSleep() {
        isAwake = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() {
        isAwake = true;
    }

    function onUpdate(dc) {
        // init
        var now  = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);

        // heart rate
        if (cachedMinute != date.min) {
            cachedMinute = date.min;
            var act = Activity.getActivityInfo();
            txtHR = act != null && act.currentHeartRate != null ? act.currentHeartRate.format("%d") : "--";

            var info = ActivityMonitor.getInfo();

            // distance
            var newtxtDistance = info.distance != null ? formatKmFromCm(info.distance) : "--";
            if (newtxtDistance != txtDistance) {
                txtDistance = newtxtDistance;
            }

            // calories
            var newtxtCalories = info.calories != null ? info.calories.format("%d") : "--";
            if (newtxtCalories != txtCalories) {
                txtCalories = newtxtCalories;
            }

            // time
            var newtxtTime = date.hour.format("%02d") + ":" + date.min.format("%02d");
            if (newtxtTime != txtTime) {
                txtTime = newtxtTime;
            }

            // pin
            var sys = System.getSystemStats();
            var newBattery = sys.battery.toNumber();
            if (newBattery != battery) {
                battery = newBattery;
                if (battery == 100) {
                    txtBattery = "100";
                } else {
                    txtBattery = battery + "%";
                }
            }
        }

        // solar date & lunar date
        if (date.day != cachedDay) {
            cachedDay = date.day;

            solar.solarYear  = date.year;
            solar.solarMonth = date.month;
            solar.solarDay   = date.day;
            cachedLunar = lunarConverter.SolarToLunar(solar);
            txtLunarDate = cachedLunar.lunarDay + "-" + cachedLunar.lunarMonth;
            
            txtDate = formatFullDate(date);
            
        }

        if (txtCalories != lastCalories) {
            lastCalories = txtCalories;
            lblCalories.setText(txtCalories);
        }

        if (txtDistance != lastSteps) {
            lastSteps = txtDistance;
            lblSteps.setText(txtDistance);
        }

        if (txtBattery != lastBattery) {
            lastBattery = txtBattery;
            lblBattery.setText(txtBattery);
        }

        if (txtDate != lastDate) {
            lastDate = txtDate;
            lblDate.setText(txtDate);
        }

        if (txtLunarDate != lastLunarDate) {
            lastLunarDate = txtLunarDate;
            lblLunarDate.setText(txtLunarDate);
        }

        if (txtTime != lastTime) {
            lastTime = txtTime;
            lblTime.setText(txtTime);
        }

        if (txtHR != lastHR) {
            lastHR = txtHR;
            lblHR.setText(txtHR);
        }

        WatchFace.onUpdate(dc);

        // ---- ICONS ----
        dc.drawBitmap(30, 150, heartBmp);
        dc.drawBitmap(97, 144, footIcon);
        dc.drawBitmap(97, 163, hotIcon);
        dc.drawBitmap(130, 59, moonIcon);
        drawBatteryIcon(dc);
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
    function drawBatteryIcon(dc) {
        var w = 38;
        var h = 17;
        var x = 85;
        var y = 188;
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, w, h);
        dc.fillRectangle(x + w, y + (h / 4), 2, h / 2);
    }
}