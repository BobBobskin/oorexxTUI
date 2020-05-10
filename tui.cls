/* 

 Text Mode UI
 v0.14
 Tom Dyer flicker@anduin.net
 2020
 
 Free to use 
 
 Written because I got bored during this Corona virus lockdown...
 
 
*/

 call rxFuncAdd "SysLoadFuncs", "REXXUTIL", "SysLoadFuncs"
 call SysLoadFuncs

 
 
 /* 
    This is the Window Manager class for the text mode UI. 
    It is primarily the dispatcher of data, and responsible for holding certain shared objects. 
    
 
 */ 

::class WindowManager public inherit SanityCheckSupported


::attribute running
::attribute logger
::attribute keyboard 
::attribute screen
::attribute window
::attribute focusableitems 
::attribute activeitem
::attribute activewindow
::attribute keybindabletasks
::attribute wmdms /* data management service for window manager, provides some validation etc */ 
::attribute wmbtm /* window manager background task management service */ 

/*
Sets up a logger, and some necessary lists 
*/

::method init

  self~running= .true /* ensure system knows it is running */ 
  
  logger=.logger~new
  screen=.screen~new
  
  self~window = .list~new
  self~focusableitems = .list~new 
  self~keybindabletasks= .list~new 
  
  self~add(logger)
  self~add(screen) /* adds a default screen, can of course be overridden with a better screen */ 
  
  keyboard= .keyboard~new()
  
  keyboard~add(self) /* gives itself to keyboard */ 
  keyboard~add(self~logger) /* gives its logger to keyboard */ 
  
  
  self~add(keyboard) /* and ensures that it has the keyboard stored in it */
  
  

  
  /*
   This is the main routine, it 
  */

::method run
    if self~running = .true then do
        self~gotoWindow(0)
        self~findfocusable /* finds the focused item on the curren window */
        self~drawwindows   /* kick off drawing the screen */
        self~logger~log("Within the WM code, about to poll keyboard",1)
        self~keyboard~poll 
        self~logger~log("We have returned from polling the keyboard",1 )
    end 
 return
 
 /*
 shortcode method to add items, 
 I have explained the purpose and thinking behind this code on other objects for example window, widget etc
 FYI. I write documentation from the bottom of the sourcecode up to the top... 
 because most developers in my experience begin by reading the documentation for the functional 
 parts of the code before they decide to dive into the "engine room" section... 
 So the reasoning is explained down there... 
 */
 
 /* Note the logger might not yet be installed at the time of runnig these commands */
 
 ::method add
    use arg obj 
    if .SanityChecker~new~check(obj ,self) = .false then return
    
 /*
 Install a temporary logger if there is none 
 */
    if .SanityChecker~new~isSet(self,"logger") = .false then do 
            l = .logger~new() 
        end 
    else 
        do 
            l = self~logger
    end 
 
 /*
    Now a select which will pick what to do with the item to add
 */ 
    select
        when obj~isInstanceOf(.window) = .true then do
            self~addWindow(obj)
            l~log("added Windows",1)
        end
        when obj~isInstanceOf(.keybindable) = .true  then do
            self~addKeyBindableTask(obj)
            l~log("added Keybindable task",1)
        end 
        when obj~isInstanceOf(.WMDataManagementService) = .true  then do
            self~wmdms = obj
            l~log("added WMDMS",1)
        end
        when obj~isInstanceOf(.WMBackgroundTaskManager) = .true  then do
            self~wmbtm = obj
            l~log("added WMBTM",1)
        end
        when obj~isInstanceOf(.screen) = .true then do 
            self~screen = obj
            l~log("added Screen",1)
        end
        when obj~isInstanceOf(.logger) = .true then do 
            /* Too early to get a logger */
            self~logger = obj
            self~logger~log("Switched from temporarly logger to installed logger",1)
        end 
        when obj~isInstanceOf(.keyboard) = .true  then do
            self~keyboard = obj
            l~log("added Keyboard",1)
        end 
        otherwise do 
            nop
        end
    end 
        
 
 ::method notifyShutdownNow 
    self~running = .false
 
 
 ::method forceWMShutdown 
    self~logger~log("forceWMShutdown Running",1)
    
    self~notifyShutdownNow
 
    if self~running = .false then do 
        if .SanityChecker~new~isSet(self,"screen") = .true then do 
        
            self~PlatformSpecificShutdownTasks
            
        end 
    end

    
    
::method PlatformSpecificShutdownTasks
    if .SanityChecker~new~isSet(self,"screen") = .true then do 
        if self~screen~platform = self~screen~isWindows then do 
            /* returnBuffersize */
            call sysTextScreenSize "BufferSize", self~screen~winbufLines, self~screen~winbufCols
        
        
        end 
        if self~screen~platform = self~screen~isLinux then do 
            self~logger~log("forceWMShutdown has screen",1)
            pid=SysQueryProcess("pid")
            self~logger~log("Killing pid" pid,1)
            Say "Forcing Kill on" pid 
            "kill -9" pid
        end 
    
    end 


 
 ::method addKeyBindableTask 
    use arg keyBindableTask 
 
    illegaltobindkey1 = .key~new("[")
    illegaltobindkey1~alt=.true
    illegaltobindkey2 = .key~new("O")
    illegaltobindkey2~alt=.true
    
    if keyBindableTask~key~detail = illegaltobindkey1~detail | keyBindableTask~key~detail = illegaltobindkey2~detail
    then do 
        self~logger~log("tried to add an illegal key binding, refused for" keyBindableTask~key~detail,1)
    end 
    else do
        
        self~logger~log("added keybindanble task to" keyBindableTask~key~detail,1)
        self~keybindabletasks~insert(keyBindableTask)
        
    end
  
 ::method addWindow 
    use arg window 
    if .SanityChecker~new~check(window,self) = .false then return
    
    window~screen = self~screen
    window~wm=self 
    self~window~insert(window)
    
    if self~window~items=1 then do 
        self~activewindow = 0
    end 
 
 ::method gotoWindow 
    use arg obj
    
    select 
        when obj~isInstanceOf(.Window) then do 
            do i = 0 to self~window~items -1 
                if obj = self~window~at(i) then windowNumber = i 
            end 
        
        end 
        otherwise do 
            windowNumber = obj 
        end 
    end /* end select */
    self~screen~majorchange = .true 
    self~activewindow= windowNumber
    self~findfocusable
  

::method findfocusable 
  self~focusableitems = .list~new 
  
  if .SanityChecker~new~isSet(self~window~at(self~activewindow),"objects") = .true then do 
    do i = 0 to self~window~at(self~activewindow)~objects~items -1 
        if (self~window~at(self~activewindow)~objects~at(i))~isInstanceOf(.focusable) then do 
            self~focusableitems~insert(self~window~at(self~activewindow)~objects~at(i))
            end
    end 
    
    if self~focusableitems~items > 1 then do
        self~focusableitems~at(0)~hasFocus = .true 
        self~activeitem= self~focusableitems~at(0)
    end 
  
    if .SanityChecker~new~isSet(self~activeitem,"validator") then do 
        self~activeitem~validator~displayValidatorText
    end 
  end 

::method nextFocus 
    self~logger~log("Changing to next focus" self~focusableitems~items,0)

  do i = 0 to self~focusableitems~items -1 
	 
	if self~focusableitems~at(i)~hasFocus = .true then do 
		self~focusableitems~at(i)~lostFocus

		if i = self~focusableitems~items -1 then do 
   			self~focusableitems~at(0)~gotFocus
			self~activeitem=self~focusableitems~at(0)
			return
		end 
		else do 
			self~focusableitems~at(i+1)~gotFocus
			self~activeitem=self~focusableitems~at(i+1)
			return
		end 
	end
  end 
  

::method drawwindows unguarded
    do i = 0 to self~window~items -1 
        self~window~at(self~activewindow)~draw
    end


::method sendkey 
    use arg key 
    self~logger~log("WM - key pressed was" key~detail,0)

    select 
        when key~altcmd= .true & upper(key~value) = "X" then do /* Alt X shutdown key */ 
            self~keyboard~running= .false
            self~screen~running = .false 
            self~logger~log("shutdown called",0)
        end
        when key~altcmd= .true & upper(key~value) = "R" then do /* Alt R redraw */
            self~drawwindows 
            self~screen~draw
        end
        when key~tab=.true then do /* Tab next field */ 
            self~nextFocus
        end 
        when key~altcmd= .true then do /* any other alt key is sent to keybindable tasks */
            /* 
            send it to anything with global keybindability on alt 
            */ 
            do i = 0 to self~keybindabletasks~items -1 
                self~logger~log("WM sending keystroke to keybindabletask",2)
                self~keybindabletasks~at(i)~sendkey(key)
            end 
        end 
        otherwise 
                self~activeitem~sendkey(key)
        end
        
        /* 
        then anything else to the active item on screen
        */
        
        self~drawwindows 

/* 
    The background task manager, registers background tasks, starts them on request, reports back their status 
*/ 
::class WMBackgroundTaskManager public subclass Directory 


    
    
    /* 
    WindowManager Data Management Service
    Provides information on whether fields and windows have been displayed, whether they validated, and allows the registration of certain data requirements
    to help for timely development at the moment it is  just a directory of fields 
    but this will be extensively improved 
*/

 
::class WMDataManagementService public subclass Directory

::method getValue 
    use arg obj 
    field = self~get(obj) 
    if field~isNil = .false then return .nil
    else do 
        return field~data 
    end 

    
    
/*

The default screen class is a fixed size, 1:1 positioning of objects. 
It has as much of the code in it for dealing with actually drawing what 
should go on the screen as possible, to allow for implementation which is 
platform specific 

*/


::class screen public inherit AlarmNotification SanityCheckSupported


::attribute logger
::attribute rows
::attribute columns 
::attribute platform 
::attribute running
::attribute data
::attribute ScreenCapabilityHighChar /* can we use highchars in the display */ 
::attribute winbufLines /* used to allow compatibility with resetting the screen in Windows */
::attribute winbufCols /* used to allow compatibility with resetting the screen in Windows */

::constant ansi '1b5b'x              /* ansi escape code */ 
 
::constant black 0
::constant red 1 
::constant green 2
::constant yellow 3
::constant blue 4
::constant magenta 5
::constant cyan 6
::constant white 7
::constant grey 8
::constant brightred 9
::constant brightgreen 10
::constant brightyellow 11
::constant brightblue 12
::constant brightmagenta 13
::constant brightcyan 14
::constant brightwhite 15

::attribute recheckScreensize 
::attribute forceClear 
::attribute MajorChange


::method ansiclear
  say self~ansi||'2J' /* clear */ 
  say self~ansi||'?25l' /* hide cursor */ 

::constant isLinux linux
::constant isWindows windows 

::method init 
  use arg logger 
  self~logger
  self~data = .mutablebuffer~new()
  self~recheckScreensize = 30  /* check every 30 seconds on repaint for screen size change */
  self~forceClear = .false 
 
  self~PlatformCheck

  self~getscreensize
  self~setalarm 
  
::method PlatformCheck 
    if pos("Linux", SysVersion()) <> 0 then do 
        self~platform=self~isLinux
    end 
    
    if pos("Windows", SysVersion()) <> 0 then do 
        self~platform =self~isWindows
        self~ScreenCapabilityHighChar= .true 
        'rem' 
            /* according to Gil Barmwater, there is a problem on Windows
            with Ansi support which doesnt wake up until it has had 
            command so on that basis, this might just make it work */
            
        parse value SysTextScreenSize("MaxWindowSize") with maxLines maxCols
        parse value SysTextScreenSize("BufferSize"   ) with self~winbufLines self~winbufCols
        parse value SysTextScreenSize("WindowRect"   ) with offLines offCols winLines winCols
        
        /* buffer to window */
        tmpLines=winLines-offLines+1
        tmpCols =winCols -offCols+1
        
        call sysTextScreenSize "BufferSize", tmpLines, tmpCols
        
        
    end 
    
    if self~platform= self~isLinux then do 
            /* 
                Set the screen to run line by line, rather than char by char, used for high latency links
                and ideal for making a programme which paints the entire screen at a time 
                function correctly.
            */ 
        
            "stty extproc" 
            self~ScreenCapabilityHighChar = .true 
        
            do line over .SystemQueue~new("echo $TERM") ; nop ; end /* $ */
                parse var line terminal
                if upper(terminal) = upper("LINUX") then do 
                    /* I think we have been opened using a full screen window on a hard tty */
                    self~recheckScreensize = 60 /* so lets minimise the number of times we check the screen size 
                                                    to the minimum */ 
                                                    
                    self~ScreenCapabilityHighChar = .false      /* full screen linux doesn't like highchar */ 
                    
                end 
    end
  

  
::method getEdge 
    if .SanityChecker~new~isSet(self,"ScreenCapabilityHighChar") = .true then do 
        if self~ScreenCapabilityHighChar = .true then do 
                edge = d2c(26)
            end 
            else do
                edge ="*"
            end 
    end 
    
    return edge 
  
  
::method setalarm unguarded
    if self~running = .false then exit 
    alarm = .alarm~new(1, self)

    
    /* 
    either given a widget where it will find the position
    or given x,y coordinates 
    */ 
  
  ::method setcursor 
    use arg obj1, obj2=.Nil
    
    select 
        when obj1~isInstanceOf(.Widget) =.true then do 
                /* ansi movement code in screen */ 
                output=self~ansi||self~getPositionRow( obj1)||";"self~getPositionColumn(obj1)||"H "
            end 
        otherwise do 
                
                output=self~ansi||obj1||";"obj2||"H "
        end 
    end 
        
    return output
    
    ::method setcolour 
    use arg obj 
    output = "" 
    if obj~isInstanceOf(.coloured) then do 
        output = self~getColourForObject(obj) 
    end 
    return output
    
    
    /* 
      relies on ansi colours working 
    */ 
    
    ::method getColourForObject
    use arg obj 
    if .SanityChecker~new~isSet(obj,"fgcolour") = .false then do
        /* default  */ 
        output = self~ansi||"39m"
    end 
    else do 
        output = self~ansi||"38;5;"||obj~fgcolour||"m" 
    end 
    
    
    /* 
     bgcolour doesn't work reliably yet, at least, I don't think it does
    */

    if .SanityChecker~new~isSet(obj,"bgcolour") = .false then do
                output = output /* don't deal with no bg colour */
    end 
    else do 
          output = output||self~ansi||"48;5;"||obj~bgcolour||"m" 
    end
    return output

::method getscreensize 
    expose rows columns

	if self~platform = self~isLinux then do 
		/* linux */ 
		do line over .SystemQueue~new("stty size ") ; nop ; end
		parse var line rows columns 
	end 

        if self~platform = self~isWindows then do 
		/* not tested but should work eh */ 
		parse value SysTextScreenSize() with rows columns
        end


::method triggered unguarded
    
    t = time(Seconds) 
    if t // self~recheckScreensize = 1 then do  /* the thinking here is getting the screen size seems to cause some flicker */
        self~getscreensize 
    end 
    
    self~draw 

::method draw 
     if self~forceClear = .true | self~MajorChange = .true then do
        self~clear 
     end 
     say self~data
     self~setalarm

/* This is the code for issuing the instruction to clear the screen.  
    On linux, it seems that Ansi clear works better than SysCls 
    So I have defaulted to that 
*/
::method clear
     self~ansiclear 
     /* call SysCls  */
 
 /*
 These methods getting the pos and row from a widget in the screen are primarily here so that they can be overridden in the virtual screen 
 */
 
 ::method getPositionRow 
    use arg widget
    return widget~row
 
 ::method getPositionColumn 
    use arg widget
    return widget~column
 
 /* 
  Virtual Screen 
  This class treats the screen as if the itens were positioned on a 80/25 display and then moves the items to fit the actual display
  This makes laying out a UI much much easier, especially if one needs it to work on a 80/25 display and also knows that 
  it might be run in a window on a GUI (I know, this is a TEXT mode UI, so heaven help us that you'd run it on a GUI)
  where the window size might change .
 */
 
 ::class VirtualScreen public subclass Screen 
 
 ::constant vColumns 80  /* this is the size it thinks you are laying out the elements for */
 ::constant vRows 25
  
 ::method init 
    use arg logger 
    self~init:super(logger) /* normal init */ 
    self~recheckScreensize = 5  /* set to check screen more frequently for size changes */ 
    self~PlatformCheck /* run platform specific checks - this isolates some platform specific code */ 
 
 
 ::method PlatformCheck 
    self~PlatformCheck:super /* try the supercode first, then do whatever additional checks and modifications we have to do */ 

    
  
 /* 
    This method returns a Postion for the Column based on a virtual screen, unless it is a fixed position widget where it will 
    use the standard fixed position location 
 */ 
  
 ::method getPositionColumn 
    use arg widget
        select 
            when widget~isInstanceOf(.FixedPositionWidget) = .true then do 
                posC = self~getPositionColumn:super(widget) /* The posiion returned for fixed position widgets is not adapted */ 
            end 
            otherwise do /* for all other widgets, we will move the object as we see apropriate */ 
                wcol = self~getPositionColumn:super(widget) 
                factor = self~columns / self~vColumns
                posC = (factor * wcol ) %1 
            end
        end 
        
    return posC
 
 
 /* 
    This method returns a Postion for the Row based on a virtual screen, unless it is a fixed position widget where it will 
    use the standard fixed position location 
 */ 
 
 ::method getPositionRow 
    use arg widget
        select 
            when widget~isInstanceOf(.FixedPositionWidget) = .true then do 
                posR = self~getPositionRow:super(widget) 
            end 
            otherwise do 
                wrow = self~getPositionRow:super(widget) 
                factor = self~rows / self~vRows
                posR = (factor * wrow)%1  
            end
        end 
    return posR 

 
 
 /* 
 Here is the keyboard. 
 It deals with polling the keyboar, and setting up the correct key codes. 
 It then gives the input to the wm to process and decide what to do with it. 
 It does not do that itself. 
  */
 
 
::class keyboard public inherit SanityCheckSupported

::attribute logger 
::attribute running 
::attribute wm

::method add 
    use arg obj 
    if obj~isInstanceOf(.WindowManager) then self~wm = obj
    if obj~isInstanceOf(.Logger) then self~logger = obj

::method poll unguarded 

 if self~running = .false then exit 
 
 /* 
    get key from keyboard 
 */ 
 
    k = sysgetkey("noecho")
 
    /*   now create an object for the key     */ 
 
    key = .key~new
   
   /*   now work out the correct treatment    */
   
    select 
    /* tab pressed, probably used for moving between fields  */ 
    when c2x(k) = .key~tabcode then do 
        key~tab=.true
        key~value=""
    end 
    /* backspace which will have special treatment */ 
    when c2x(k) = .key~bscode then do 
        key~bs=.true 
        key~value=""
    end
    /* space needs some care as well */ 
    when c2x(k) = .key~spacecode then do 
        key~space=.true
        key~value=" "
    end
    /*  if an alt button pressed, we need the next key to determine what was actually pressed */ 
    /*  special keyboard control characters such as F1 -> F12, and arrow keys need multiple buttons */
    when c2x(k) = .key~altcode then do 
    
        k2 =sysgetkey("noecho")
        
        select
            when c2x(k2)= "4F" then do 
                /* We've got a special control character such as fn buttons which use 3 parts */
                /* note, because of this you cannot bind to ALT-O alone, and I added code to ensure that 
                a key task won't bind to this, or another illegal combination in the WM */ 
                 
                k3 = c2x(sysgetkey("noecho"))
                
                self~logger~log(k1 k2 k3,1)
                
                /* I know, this could be neater */ 
                select 
                    when k3 = .key~fn1code then do
                        key~fn1 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn2code then do
                        key~fn2 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn3code then do
                        key~fn3 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn4code then do
                        key~fn4 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn5code then do
                        key~fn5 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn6code then do
                        key~fn6 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn7code then do
                        key~fn7 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn8code then do
                        key~fn8 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn9code then do
                        key~fn9 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn10code then do
                        key~fn10 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn11code then do
                        key~fn11 = .true
                        key~fnbuttons = .true
                    end
                    when k3 = .key~fn12code then do
                        key~fn12 = .true
                        key~fnbuttons = .true
                    end
                    otherwise do
                    
                    end 
                end 
                if key~fnbuttons = .true then key~altcmd = .true
            end 
            when k2 = "[" then do
                /* We've got a special control character such as an arrow key which uses 3 parts */
                k3 = c2x(sysgetkey("noecho"))
                self~logger~log("arrows" k1 k2 k3,1)
                select 
                    when k3 = .key~backtabcode then do
                        key~backtab = .true
                    end
                    when k3 = .key~uparrowcode then do
                        key~uparrow = .true
                        key~arrows = .true 
                    end
                    when k3 = .key~downarrowcode then do
                        key~downarrow = .true
                        key~arrows = .true 
                    end
                    when k3 = .key~rightarrowcode then do
                        key~rightarrow = .true
                        key~arrows = .true 
                    end
                    when k3 = .key~leftarrowcode then do
                        key~leftarrow = .true
                        key~arrows = .true 
                    end
                    when k3 = "5B" then do 
                    /* we are on a linux full screen terminal which sends 4 chars for each*/ 
                        k4 = c2x(sysgetkey("noecho"))
                        select 
                            when k4 = "41" then do 
                                key~fn1 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "42" then do 
                                key~fn2 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "43" then do 
                                key~fn3 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "44" then do 
                                key~fn4 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "45" then do 
                                key~fn5 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "46" then do 
                                key~fn6 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "47" then do 
                                key~fn7 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "48" then do 
                                key~fn8 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "49" then do 
                                key~fn9 = .true
                                key~fnbuttons = .true
                            end
                            when k4 = "10" then do 
                                key~fn10 = .true
                                key~fnbuttons = .true
                            end
                            otherwise do 
                                nop
                            end 
                        end 
                    if key~fnbuttons = .true then key~altcmd = .true
                    end 
                    /* we are not handling these keys */
                    otherwise do 
                        nop
                    end 
                end 
                key~value=""
            end
            /* the key that was pressed was a standard ALT key such as ALT-P which uses 2 parts */
            otherwise do
                key~alt=.true
                key~altcmd = .true
                key~value= k2 
            end 
        end 
    end
    /* it seems that it was a normal keystroke, so let's just set the value */
    otherwise do 
        key~value = k
        end 
    end 
    

    self~logger~log("keyboard class sending " key~detail(), 2)
    /* 
    Now hand the job of working out what to do to the Window Manager 
    */
    self~wm~sendkey(key)
    
    /*
    and kick off the poll again... 
    */ 
    
    self~poll

 
 /*
  Class for keys used to handle input 
 */ 

::class key public 

::constant altcode "1B"
::constant tabcode "09"
::constant spacecode "20" 
::constant bscode "7F" 
::constant backtabcode "5A" /* 1B 5B 5A */
::constant uparrowcode "41" /* 1B 5B 41 */
::constant downarrowcode "42" /* 1B 5B 42 */
::constant rightarrowcode "43" /* 1B 5B 43 */
::constant leftarrowcode "44" /* 1B 5B 44 */
::constant fn1code 50
::constant fn2code 51
::constant fn3code 52
::constant fn4code 53
::constant fn5code 54
::constant fn6code 55
::constant fn7code 56
::constant fn8code 57
::constant fn9code 58
::constant fn10code 59
::constant fn11code 60
::constant fn12code 61

::attribute alt 
::attribute altcmd 
::attribute tab 
::attribute value
::attribute space
::attribute bs
::attribute arrows 
::attribute uparrow
::attribute downarrow
::attribute rightarrow
::attribute leftarrow
::attribute backtab
::attribute fnbuttons
::attribute fn1
::attribute fn2
::attribute fn3
::attribute fn4
::attribute fn5
::attribute fn6
::attribute fn7
::attribute fn8
::attribute fn9
::attribute fn10
::attribute fn11
::attribute fn12


/* 
 Comparison method for keys 
*/
::method "=" 
    use arg obj 

    /* 
    By default they don't match 
    */ 

    rc = .false
    select 
        when obj~isInstanceOf(.Key) then do 
            /* if both keys then compare detail */ 
            if obj~detail = self~detail then rc = .true
        end 
        when obj~isInstanceOf(.String) then do 
            /* if one is a string and the other is special, they can't match */ 
            if self~isSpecial = .true then rc = .false
        else do
            /* if it's not a special, then try comparing the letters themselves caseless*/
            if upper(obj)= upper(self~value) then rc = .true
        end
    end 
    otherwise 
        rc = .false
    end 
    return rc 



::method get 
    expose value 
    return value 

::method isSpecial 
    if self~alt = .true | self~tab = .true | self~space = .true | self~bs = .true | self~uparrow = .true | self~downarrow = .true | self~rightarrow = .true | self~leftarrow = .true | self~backtab = .true | self~fn1 = .true | self~fn2 = .true | self~fn3 = .true | self~fn4 = .true | self~fn5 = .true | self~fn6 = .true | self~fn7 = .true | self~fn8 = .true | self~fn9 = .true | self~fn10 = .true | self~fn11 = .true | self~fn12 = .true then return .true 
    else 
    return .false 

::method init
    use arg kv=""
    self~value= kv

/*
    detail of the key object written - in long form
*/ 
::method detail
    rv = upper(self~value) c2x(upper(self~value)) self~alt self~tab self~space self~bs self~uparrow self~downarrow self~rightarrow self~leftarrow self~backtab self~fn1 self~fn2 self~fn3 self~fn4 self~fn5 self~fn6 self~fn7 self~fn8 self~fn9 self~fn10 self~fn11 self~fn12 
    return rv 



/* 
 This isn't anywhere near working but if you uncomment the lineouts.. you can get some output 
*/

::class logger public 
::attribute logdata 
::attribute running 

::method init 
  expose stem
  use arg stem=.nil
  
  self~logdata = .list~new 
   
::method log
    expose loglevel 
    use arg message, level

    if level > loglevel then do
        self~logdata~insert(message)
        rc=lineout("logfile",message)  /* I know, filthy */
    end 

::method setloglevel
    expose loglevel 
    parse arg loglevel 
 
::method unknown
  expose stem
  use arg msg, text
  stem[0] += 1
  index = stem[0]
  stem[index] = text~makeString
  self~log(msg,9)
  self~log(text,9)
  self~log(text~makeString,9)
 

 /*
  A window to the soul 
 */
 
::class Window public inherit SanityCheckSupported coloured 
::attribute name 
::attribute screen
::attribute objects
::attribute wm 
::attribute logger

::method init 
    self~objects = .list~new

::method draw 
    self~makewindow 
    self~screen~data = self~makewindow

::method makewindow 
    d = self~screen~setcolour(self)
    
    /* self~screen~clear */
    
    edge = self~screen~getEdge()
       
    
    d = d||self~maketitlebar(edge)
    
    
    do i = 1 to self~screen~rows-2
        d=d||self~screen~setcursor(i,1)||edge|| self~screen~setcursor(i,self~screen~columns-1)||edge 
    end

    /* It's important to have the time on screen so people can see something is working */
    time = time() 
    d = d||" "||center(time, self~screen~columns-1, edge)


    /* loop through the items on screen and get them to draw */
    do i = 0 to self~objects~items -1 
        d=d||self~screen~setcolour(self~objects~at(i))
        d=d||self~screen~setcursor(self~objects~at(i))
        d=d||self~objects~at(i)~draw
    end
    
    d=d||self~screen~setcursor(self~wm~activeitem) /* moves the cursor at least to the correct line */ 

    return d 

::method maketitlebar
    use arg edge="*"
    titlebar = self~screen~setcursor(0,1)||center( self~name, self~screen~columns, edge)
    return titlebar 

/*
 Windows have a standard shared "add" method like widgets and WindowManager, for the same reason
 by having a single add method which then executes the correct putter based on the type, it makes the 
 front end layout code easier to maintain. 
*/ 

::method add 
    use arg obj 
    if .SanityChecker~new~check(obj,self) = .false then return
    if obj~isInstanceOf(.widget) then do 
        self~objects~insert(obj)
    end 
    if obj~isInstanceOf(.keybindable) then do  /* bind against the wm instead - fix for common error */
        self~wm~add(obj)
    end 



/*
 This is a stub for an idea 
*/ 

::class logwindow subclass window
::attribute logger 

::method draw 
    super~draw 
    do i = 1 to logger~logdata~allItems
        self~screen~data(logger~logdata[i])
    end 



/* 
widgets classes 

*/

/* 
 The standard widget class 
*/
::class widget public inherit coloured 
::attribute row
::attribute column
::attribute data 
::attribute disdata 
::attribute validator 

::method predraw 
    self~disdata = self~data

::method draw 
    self~predraw 
    return self~disdata 


::method init 
    expose data row column 
    use arg data, row , column
    self~row = row +1 
    self~column = column +1 


/* 
 the purpose of these single "add" methods which then assign the item based on the type
 is to simplify the process when you are designing a UI. It means that you don't have to think too hard 
 about what the object classes are, and remember what the appropriate putter method is when you want to assign them. 
*/ 

::method add
  use arg obj 
  /* I probably should improve the sanity checker */ 
  if .SanityChecker~new~check(obj) = .false then return
  
  if obj~isInstanceOf(.validator) = .true then self~validator = obj
  /* assume that any label being added to a widget is actually the field help field */
  if obj~isInstanceOf(.label) = .true then self~validator~fieldhelp = obj 
  /* assume that we are trying to set the field help */
  if obj~isInstanceOf(.string) = .true then self~validator~fieldhelpstring = obj 
  
   

/* labels are boring but necessary, otherwise people don't know what fields are for */

::class label public subclass widget

/*everyone needs a button */

::class button public subclass widget inherit focusable focuscoloured 
::attribute length
::attribute task 

::method init 
expose length
use arg data, row, column, length
self~init:super(data, row, column)

::method predraw 
self~disdata = "["||center(self~data,self~length-2," ")||"]"

if self~hasFocus = .true then do 
self~disdata = self~disdata ||" * "
end

::method sendkey 
self~task~run

::method add 
use arg obj 
if obj~isInstanceOf(.Task) then do 
    self~task = obj
end 
self~add:super(obj) 



/* 
The standard Input box
*/

::class inputbox public subclass widget inherit focusable clearable focuscoloured 
::attribute length 
::attribute fixedlength 
::attribute showlength 

::method init
expose data row column length
use arg data, row, column, length 
self~validator = .validator~new() /* default validator used */
self~fixedlength = .nil
self~init:super(data, row, column) 
 
::method predraw 
self~disdata = left(self~data,self~length,"_") 
if self~hasFocus = .true then do 
    self~disdata = self~disdata ||" *"
end 

if self~showlength= .true then do 
    if self~fixedlength = .true then do 
    self~disdata = self~disdata length(self~data)||"/"||self~length
    end 
    else self~disdata = self~disdata length(self~data) 
end 

::method sendkey 
use arg key
if key~bs = .true & length(self~data ) > 0  then do
	self~data = left(self~data, length(self~data)-1 )
end 
else do
  if .SanityChecker~new~isSet(self,"validator") = .true then do 
  	if self~validator~isValidKey(key) = .false then key~value = ""
  end 
  /* 
   can't type too much in a fixed length field 
  */ 
   if self~fixedlength = .true then do 
    if length(self~data)+1 > self~length then key~value = ""
   end 
   self~data = self~data||key~value
end 

/*
 Search box, allows you to provide a list of potential 
 options, which can then be found when you type part of the option 
*/
::class searchbox public subclass inputbox 
::attribute list 
::attribute keyed 
::attribute matching 

::method init
use arg data, row, column, length 
self~keyed=""
self~matching=0
self~init:super(data,row,column,length)

::method sendkey
    use arg key 
    self~sendkey:super(key) 
    self~matching = 0 

    if key~bs = .true then do 
        if length(self~keyed) >= 1 then do
            self~keyed = strip(left(self~keyed,length(self~keyed)-1))
            
        end 
    end 
    else do 
        self~keyed = self~keyed||key~value
    end 

    do i = 0 to self~list~items -1 
        if upper(self~keyed) = upper(left(self~list~at(i),length(self~keyed))) then do
        self~matching = self~matching + 1 
        self~data = self~list~at(i)
        end 
    end 
    
    if self~matching = 0 then self~data = ""


::method predraw 
    self~predraw:super()
    self~disdata = self~disdata || " Matching " self~matching


/*
 Password box doesn't show entry 
*/

::class passwordbox public subclass inputbox 
::method predraw 
self~disdata = left(copies("*",self~data~length),self~length,"_")
if self~hasFocus = .true then do 
self~disdata = self~disdata ||" P "
end


/* 
 Slider control 
 Can be set readonly and used as a % status bar 
*/

::class slider public subclass inputbox 

::attribute min
::attribute max 
::attribute readonly 

::method init 
    use arg data, min, max, row, column, length
    self~validator = .numericvalidator~new
    self~readonly = .false

    self~min = min 
    self~max = max 
    self~init:super(data, row,column,length) 
    self~checkinrange


::method sendkey 
    use arg key 
        if self~readonly = .false then do 
            select 
                when key~leftarrow = .true | key~value = "-" then do 
                    self~data = self~data - 1 
                end 
                when key~rightarrow = .true | key~value = "+" then do 
                    self~data = self~data + 1 
                end 
                when key~uparrow = .true then do 
                    self~data = self~data + (((self~max - self~min)*0.1)%1)
                end 
                when key~downarrow = .true then do 
                    self~data = self~data - (((self~max - self~min)*0.1)%1)
                end 
                when key~bs = .true then do 
                    self~data = self~min
                    self~sendkey:super(key)
                end 
                
                otherwise do
                    self~sendkey:super(key)
                end 
            end
        end 

::method checkinrange
    if self~data = "" then self~data = self~min
    if self~data < self~min then self~data = self~min
    if self~data > self~max then self~data = self~max

::method predraw 

    self~checkinrange
    diff = self~max - self~min 
    valperdiff = self~data / diff
    boxes = (self~length * valperdiff) %1
    self~disdata = left(copies("#",boxes),self~length,".") ||" "|| abs(self~data)

    if self~hasFocus = .true & self~readonly = .false then do 
        self~disdata = self~disdata ||" +/- ("||self~min "->" self~max||")" 
    end 




/*
 Radio box allows selection of a single option from a display
*/

::class radiobox public subclass inputbox
::attribute options
::attribute selected

::method init
    use arg opts, row, column, length
    if .SanityChecker~new~check(opts) = .false then do 
        self~lackingrequiredobject = .true
    end 

    self~options= .list~new 
    self~options= opts
    self~selected = 0
    self~init:super(self~options~at(0),row, column, length)

::method predraw 
    self~disdata = ""
    do i = 0 to self~options~items -1 
    if i = self~selected then do
        self~disdata = self~disdata || "X " ||  self~options~at(i) ||" "  
    end 
    else do 
        self~disdata = self~disdata || ". " ||  self~options~at(i) ||" " 
    end 
    end 
    if self~hasFocus = .true then do 
        self~disdata = self~disdata ||"*"
    end 

::method sendkey 
    use arg key 
    
    select 
        when key~leftarrow = .true then do 
            self~selected = self~selected -1 
                if self~selected < 0 then do
                    self~selected = self~options~items -1 
                end
            
            self~data = self~options~at(self~selected)
        end 
        
        otherwise do 
           self~selected = self~selected + 1 
            if self~selected = self~options~items then self~selected = 0
            self~data = self~options~at(self~selected)
        end 
    end 

::method clear 
    self~selected = 0
    self~data=self~options~at(0)


/* 
 data entry validators 
*/

/* 
normal validator letters and numbers 
*/ 


::class validator public 
::attribute validkeys 
::attribute fieldhelpstring
::attribute fieldhelp

::method init
    use arg fieldhelp=.nil
    self~validkeys = .string~graph || " £" 
    self~fieldhelpstring = "This field is alphanumeric" 
    self~fieldhelp = fieldhelp

::method displayValidatorText 
    if .SanityChecker~new~isSet(self,"fieldhelp") = .true then do 
        self~fieldhelp~data = self~fieldhelpstring 
    end 

::method clearValidatorText 
    if .SanityChecker~new~isSet(self,"fieldhelp") = .true then do 
        self~fieldhelp~data = ""
    end 


::method isValidKey
    use arg key 
    self~displayValidatorText 


    if pos(key~value, self~validkeys) > 0 then return .true 
    else return .false 

::method fieldContentValidate
    use arg widget 
    if widget~isInstanceOf(.validatable) then do 
        self~validatedata(widget)
    end 


/*
numeric entry only validator
*/ 

::class numericvalidator public subclass validator

::method init
    use arg fieldhelp=.nil
    self~init:super(fieldhelp)
    self~validkeys = .string~digit
    self~fieldhelpstring = "This field is numeric only" 




/*
 mixinclasses here 
*/

/*
  Focusable allows an item to get focus. 
*/

::class focusable public mixinclass object 
::attribute hasFocus 

::method gotFocus 
    self~hasfocus = .true 
    if self~isInstanceOf(.focuscoloured) then do 
        self~changetoFocusColour()
    end 

    if .SanityChecker~new~isSet(self,"validator") = .true then do 
            self~validator~displayValidatorText
    end 

::method lostFocus
    self~hasfocus = .false
    if self~isInstanceOf(.focuscoloured) then do 
        self~changetoDefaultColour()
    end 

    if .SanityChecker~new~isSet(self,"validator") = .true then do 
            self~validator~clearValidatorText
    end 


/* 
    mixin task which will allow validatable field results 
*/ 
::class validatable public mixinclass object
::attribute valid


::class HasMenuItems public mixinclass Object 

::attribute menuitems 

::method initMenuItems
    self~menuitems = .bag~new()

::method add 
    use arg obj 
    if obj~isInstanceOf(.menuitem) = .true then do 
        self~menuitems~append(obj)
    end 


/*
 clears fields to have blank by default. radio boxes need different treatment and to override this 
*/

::class clearable public mixinclass object 
::method clear
    self~data = "" 


/*
  allows items to be coloured 
*/
::class coloured public mixinclass object
::attribute fgcolour
::attribute bgcolour 

/* 
 allows items to have focus colouring
*/ 

::class focuscoloured public mixinclass object inherit coloured  
::attribute focusfgcolour 
::attribute defaultfgcolour 

::method changetoFocusColour 

    if .SanityChecker~new~isSet(self,"focusfgcolour") = .true then do 
        self~fgcolour = self~focusfgcolour
    end 

::method changetoDefaultColour 
    if .SanityChecker~new~isSet(self,"defaultfgcolour") = .true then do 
        self~fgcolour = self~defaultfgcolour 
    end 



/*
 used to make keybindable tasks 
*/
::class keybindable public mixinclass object
::attribute key

::method sendkey 
    use arg keypressed 
    if self~key= keypressed then do 
        self~run()
    end 


/*
I have no idea what I was thinking when I added this, but I am sure that it will come in useful
*/ 

::class SanityCheckSupported public mixinclass object
::method SanityCheckLog
    use arg msg
    self~logger~log(self " " msg,2)

/* 
Fixed Postion Widget, used to ensure that even if the screen is a virtual screen, that the position of items remains precisely as specified.
*/

::class FixedPositionWidget public mixinclass object


/*
 because it's nice to have nice code for dealing with queues etc.
 I have been told by someone that oorexx v5 has some better way of doing this
 so maybe, if someone can improve this, it will be a bit better. 
*/

::class SystemQueue public subclass RexxQueue
::method init
    use strict arg command
    command "| rxqueue"
    self~init:super

/* 
 something to make a  crashfile
 debugging this application isn't the easiest
 
*/ 

::class trapout public
::method init
   expose stem crashfile
   use arg stem
   crashfile = "crashfile"

::method unknown
   expose stem crashfile
   use arg msg, text
   stem[0] += 1
   index = stem[0]
   stem[index] = text~makeString
    .error~destination
    
    



/* 
Because it's not particularly easy if you insert a misformed object or widget, this SanityChecker is called to ensure that objects are correctly initialised
prior to adding them to a window, windowmanager, task etc.
*/
 
::class SanityChecker public 
::attribute errorcheckcode
::attribute logger
::attribute errorreason 

::method check
    use arg obj, callingobj=.nil

    self~logger=.logger~new

    if callingobj <> .nil then do 
        if callingobj~isInstanceOf(.SanityCheckSupported) then do 
            
            response = self~performcheck(obj)
            if response = .false then do
                callingobj~SanityCheckLog("Problem "self~errorcheckcode "with object" obj "called from" callingobj)
            end
        end 
    end
    else do /* not able to notify back */
        response = self~performcheck(obj)
    end 

    return response

::method performcheck 
    expose checkerrorcode 
    use arg obj 

    if obj~isnil = .true then do 
        say "SanityChecker failed on" obj
        return .false
    end 

    return .true

/* 
    where was I going here? 
*/ 
::method hasValue
    use arg obj, message
    ohm = obj~hasMethod(message)
    temporaryresponse = obj~method(message)


/* 
    Sanity check code to see if attribute is set or has a default value
*/ 
::method isSet
    use arg obj, message 
    if message~isNil = .true then do 
            self~errorreason = "Potential Development issue, nil result coming from attribute has been sent rather than a string with the attribute name to check"
            rc = .false
        end
    else do 
        ohm = obj~hasMethod(message)
        if ohm = 1 /* method exists */ then do  
            rfm = obj~send(message)
            select 
                when rfm~isNil = .true then do 
                    rc = .false 
                    self~errorreason = "is nil"
                end 
                when rfm = UPPER(MESSAGE) then do 
                    rc = .false 
                    self~errorreason = "value is unset and returning with name of a method in class"
                    if message == UPPER(MESSAGE) then do
                        self~errorreason = "Potential Dev issue, you may have passed method result rather than name of Method"
                    end
                end 
            otherwise do
                    rc = .true
                end 
            end
        end 
        else do 
            rc = .false 
            self~errorreason = "Method does not exist"
        end
    end
    return rc



/* 
 override this to perform a job when action occurs 
*/ 
::class Task public
::attribute window 

::method init 
    use arg window 
    self~add(window)

::method run 
/* override this method */ 

/* 
  standard add model code 
*/ 

::method add 
    use arg obj 
    if obj~isInstanceOf(.Window) then do 
        self~window = obj
    end 


/*
 example task to clear the fields
*/
::class clearEntryTask public subclass Task

::method run 
    do i = 0 to (self~window~objects~items -1)
    if self~window~objects~at(i)~isInstanceOf(.clearable) = .true then do 
        self~window~objects~at(i)~clear
        end
    end 

/* 
 Task to move to a specific window 
*/

::class goToWindowTask public subclass Task
::attribute windownumber 

::method init 
  use arg win, windownumber
  self~windownumber = windownumber
  self~init:super(win)

::method run 
  self~window~wm~gotoWindow(self~windownumber)
  


/*
 this isn't a button, this is registered against a keystroke. Works the same way though
*/
::class goToWindowTaskkey public subclass goToWindowTask inherit keybindable

/* 

A task which puts the current value of all the fields into a file. 

*/ 


::class printAllFieldsToFile public subclass Task 

::method run 
    do i over self~window~wm~wmdms~allIndexes
        call lineout "fields.txt", i " " self~window~wm~wmdms~at(i) " " self~window~wm~wmdms~at(i)~data
    end 


/* 

Class to create a help window 
Text is loaded from a file 

*/ 


::class CreateHelpWindowTask public subclass Task inherit keybindable 

::method run 
    parent = self~window 
    newwin = .Window~new
    newwin~name = "Help"
    i = 1
    do while lines("helpfile.txt")
        label.i = .label~new(linein("helpfile.txt"), i+2, 3)
        newwin~add(label.i) 
        i=i+1
    end 
    button = .Button~new("Close Help",20,33,20)
    button~add(.goToWindowTask~new(parent,parent))
    newwin~add(button)
    parent~wm~add(newwin) 
    parent~wm~goToWindow(newwin)

    
/*  
Run background task 
*/ 

::class BackgroundTaskStarter public subclass Task inherit keybindable AlarmNotification

::attribute backgroundtaskmanager 
::attribute backgroundtask
::attribute widget 
::attribute progress 

::method init 
    use arg backgroundtaskmanager, task, win, widget 
    self~add(backgroundtaskmanager)
    self~add(task) 
    self~add(widget)
    
    self~init:super(win) 
    self~progress = .RexxQueue~new()
    

::method run 
    Ticker = .ticker~new(0.5,self,"update")
    "rexx testtask.rex|rxqueue "|| self~progress " &"
    
    
::method triggered 
    use arg ticker 
    if self~progress~queued > 0 then do 
        self~widget~data = self~progress~pull()
        self~window~draw()
    end 
    
    /* 
        Add method 
    */ 

::method add
    use arg obj 
    select 
        when obj~isInstanceOf(.WMBackgroundTaskManager) = .true then do 
        self~backgroundtaskmanager = obj
        end 
        when obj~isInstanceOf(.BackgroundTask) = .true then do 
            self~backgroundtask~name = obj
        end 
        when obj~isInstanceOf(.String) = .true  then do /* name of bg task */ 
            self~backgroundtask = obj
        end 
        when obj~isInstanceOf(.Widget) = .true then do 
            self~widget = obj
        end 
        otherwise do 
            self~add:super(obj) /* try the super add */ 
        end 
    end 


::class BackgroundTask public subclass Task 
    
    
    
/*  
 task which runs on keypress, updating a value 
 This is one method of running a task 
 you will note that testtask.rex just counts slowly 1-100
*/ 

::class ProgressTask public subclass Task inherit keybindable AlarmNotification

::attribute widget 
::attribute progress 

::method init 
    use arg win, widget 
    self~add(widget)
    self~init:super(win) 
    self~add(.RexxQueue~new("prog1234"))
    

::method run 
    Ticker = .ticker~new(0.5,self,"update" )
    "rexx testtask.rex|rxqueue "|| self~progress " &"
    
    
::method triggered 
    use arg ticker 
    if self~progress~queued > 0 then do 
        self~widget~data = self~progress~pull()
        self~window~draw()
        
    end 
    
::method add
    use arg obj 
    select 
        when obj~isInstanceOf(.Widget) then do 
        self~widget = obj
        end 
        when obj~isInstanceOf(.RexxQueue) then do 
            self~progress = obj
        end 
        otherwise do 
            self~add:super(obj) /* try the super add */ 
        end 
    end 

::class menu public subclass widget inherit FixedPositionWidget HasMenuItems
::attribute wm


::method init 
    use arg wm 
    self~wm = wm 

    self~initMenuItems

    self~init:super("",1,2)
    self~data = "" 

::method predraw

    if self~menuitems~at(0)~isNil = .false then do 
            data = self~menuitems~at(0)~name
            say data
        end 
        
    self~predraw:super()



::class menuitem public subclass widget inherit FixedPositionWidget HasMenuItems
::attribute task 

::method init 
    use arg name, task
    self~data = name 
    self~task = task 
    self~initMenuItems


