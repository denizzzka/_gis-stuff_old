module sfml;

import sf.graphics;

import std.string;
import std.exception;


void init()
{
    sfVideoMode vmode = { 800, 600 };
    sfContextSettings settings = { 24 };
    
	auto screen = new RenderWindow(
        vmode,
        "Game",
        sfDefaultStyle,
        &settings
    );

	auto font = new Font("arial.ttf");
	auto text = new Text();
	text.font = font;
	text.string = "Hello world";
	text.color = sfBlue;
	text.position = sfVector2f(10,10);

	sfEvent ev;

	while(screen.isOpen)
	{	
		while(screen.pollEvent(&ev))
		{
			if(ev.type == sfEvtClosed)
				screen.close();
		}

		screen.clear(sfBlack);
		screen.draw(text, null);			
		screen.display();

	}
}
