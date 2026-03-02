import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class Background extends WatchUi.Drawable {

    function initialize() {
        var dictionary = {
            :identifier => "Background"
        };

        Drawable.initialize(dictionary);
    }

    function draw(dc as Dc) as Void {
        var bg = Application.Properties.getValue("BackgroundColor");
        var color = (bg != null) ? bg as Number : Graphics.COLOR_WHITE;
        dc.setColor(color, color);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    }

}
