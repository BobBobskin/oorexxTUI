# oorexxTUI
ooRexx based Text Mode User Interface class
Notes are correct as of v 0.14 or there abouts, and are not intended as being binding on the future direction of travel 

requires oorexx v5 beta or beta 
tested on linux 

no warranty, free to use. 


** So what do we have here. **
tui.cls is an attempt at making a text mode user interface class, which will work both on Windows (untested as I haven't actually had a computer of my own which used Window since the release of OS/2 v2 (if you can believe that), OS/2 (which sadly I cannot test, at the moment, as my only remaining OS/2 machine is currently running abroad, and without flying there to go and stand in a frigid server centre, so that I can get to the console to test the programme on a machine which is running a live platform and which hasn't had anyone physically look at it, let alone interact with the programs which have been running on it, day in, day out, for the best part of a decade and a half, it's going to be little bit difficault to test (maybe ... if there is demand, I'll find an excuse to install OS/2 in a virtual box to test it)), Linux (both full screen terminals and Winndowed terminals) and potentially I should be able to make it also run on Mac as wll (however, that will only occur when I get around to kicking my better half off her laptop, so that I can test it on that platform). 

The intention behind the way the methods and objects are laid out, is to ensure that, as far as possible, someone having to implement a front end using the system needs to know as little as possible, and certainly does not need to have an indepth knowledge of the classes, to be able to at least create a basic front end, with labels, input boxes and a button which can then do something with the input from the screen. 

To that end, where possible, The WindowManager and Windows have a method "add", which takes an object, and which then determines, by virtue of the object class, what the intended purpose and correct behaviour desired is going to be. 

** Example application **

In demonstrating any class, it is, of course, necessary to provide a HelloWorld example, of which one is now provided. 
It uses the most default scren, without colouring, and reasonably simple widgets to perform the tasks. ie. open a window and then close when you press any key. 






