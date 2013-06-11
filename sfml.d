module sfml;

import sf.system;
import sf.window;
import sf.graphics;

import std.string;
import std.exception;


void init()
{
	auto screen = new RenderWindow(
        VideoMode(800, 600),
        "Game",
        WindowStyle.Default,
        null);

	auto font = new Font("arial.ttf");
	auto text = new Text();
	text.font = font;
	text.string = "Hello world";
	text.color = Color.Blue;
	text.position = sfVector2f(10,10);

	Event ev;

	while(screen.isOpen)
	{	
		while(screen.pollEvent(&ev))
		{
			if(ev.type == EventType.Closed)
				screen.close();
		}

		screen.clear(Color.Black);
		screen.draw(text, null);			
		screen.display();

	}
}
