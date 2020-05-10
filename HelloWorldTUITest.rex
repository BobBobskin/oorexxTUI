/*  Example HelloWorld application
    This creates a very minimal 

*/ 

/* Create a Window Manager */ 
wm = .windowmanager~new()

/* Create a Window */ 
win = .window~new

/* Set the Window Title */ 
 win~name = "Hello World Test Application" 

/* Put a lable on the screen with the text Hello World at 10 10 on a standard 80,25 display */
label = .label~new("Hello World",10,10) 

/* Put a button on the screen, which when pressed will create a special task internally to send a message to the WM with the command "forceWMShutdown" to close the application */ 
button = .ButtonSendMessage~new("Close Application", 20,29,20, wm, "forceWMShutdown" ) 

/* Add the Label to the Window */
win~add(label)

/* Add the Button to the Window */
win~add(button)

/* Add Window to Window Manager */ 
wm~add(win)

/* Run Window Manager */ 
wm~run()

/* Terminate Window Manager*/
wm~forceWMShutdown()

exit 


::requires "tui.cls"
