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
        dc.setColor(0x000000, 0x000000);
        dc.fillRectangle(0, 0, dc.getWidth(), dc.getHeight());
    }

}
