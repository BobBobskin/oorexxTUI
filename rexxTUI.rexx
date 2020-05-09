/* 

Test rexx app for UI
version 0.1 

*/

/*
 some code to get a crash file in case everything goes pearshaped
*/
  out.0 = 0   -- create the stem
  pdest = .error~destination(.trapout~new(out.))

  /* 
  main example code
  */

/*
 create the window manager and set logging level
*/
  
 wm = .windowmanager~new()
 
 wm~logger~setloglevel(-1)
 
 
 wmdms =.WMDataManagementService~new 
 
 /* 
 create a window 
 */
 
 
 win = .window~new
 win~logger=wm~logger 
 win= .window~new
 win~name = "Window number 1" 
 
 
 win~bgcolour= .screen~blue
 win~fgcolour= .screen~white
 
 secondwin= .window~new
 secondwin~name = "Window number 2" 
 secondwin~logger = wm~logger 
 secondwin~bgcolour= .screen~blue
 secondwin~fgcolour= .screen~brightyellow 

 /* 
 create some elements for the windows 
  */
 
 
 label1 = .label~new("this is a label",2,2) 
 label2 = .label~new("a second label", 3,2) 
 input1 = .inputbox~new("", 2, 18, 30)
 input1~fixedlength=.false
 input1~showlength=.true
 
 input1~focusfgcolour = .screen~brightgreen
 
 input2 = .inputbox~new("", 3, 18, 30)
 input2~showlength=.true
 input2~fixedlength=.true
 
 input2~fgcolour = .screen~green
 input2~focusfgcolour = .screen~brightyellow
 
 input3 = .passwordbox~new("", 4, 18, 30)
 input3~fgcolour = .screen~green
 input3~focusfgcolour = .screen~brightgreen

 radiooptions = .list~new
 radiooptions~insert("Free like beer")
 radiooptions~insert( "Free like speech") 
 radiooptions~insert("Freedom to bare arms") 
 input4 = .radiobox~new(radiooptions, 5,18,40)
 input4~fgcolour = .screen~yellow
 fieldhelplabel = .label~new("** I am sure I am not here **",15,18) 
 
 
 input1s2 = .inputbox~new("",2, 18, 30)
 input2s2 = .searchbox~new("", 3, 18, 30)
 input2s2~list=.list~new()
 input2s2~list~insert("Dasha")
 input2s2~list~insert("Dusy")
 input2s2~list~insert("Thomas")
 input2s2~list~insert("Bob")
 input2s2~list~insert("Marina")
 input2s2~list~insert("Martin")
 input2s2~list~insert("Arthur")
 input2s2~list~insert("Tamsyn")
 
 input2s2~fgcolour=.screen~brightyellow
 
 
 sliders2 = .slider~new(10,5,400,4,18,30) /* initial value 10, range 5-400 */
 
 sliders2ro = .slider~new(0,0,100,6,18,50)  /* a read only slider */
 sliders2ro~readonly=.true
 say sliders2ro~data 
   
 label3s2 = .label~new("", 4,3) 
 
 
 /*
 set up a couple of field validators 
 The 
 */
 
 input1~add(.validator~new(fieldhelplabel))
 input2~add(.numericvalidator~new(fieldhelplabel))
  
 

 /*
 keyboard listening tasks which executes code ... the same tasks can also be used on buttons 
 */
 
 task1= .goToWindowTaskKey~new(win,1)
 task1~key=.key~new("N")
 task1~key~alt=.true 
 
 task2= .goToWindowTaskKey~new(win,0)
 task2~key=.key~new("P")
 task2~key~alt=.true
 
 helpwintask = .CreateHelpWindowTask~new(win) 
 helpwintask~key=.key~new("H")
 helpwintask~key~alt=.true

 helpwintask2 = .CreateHelpWindowTask~new(win) 
 helpwintask2~key=.key~new
 helpwintask2~key~fn1=.true
 
 
 ProgTask = .ProgressTask~new(secondwin, sliders2ro)
 ProgTask~key=.key~new
 ProgTask~key~fn2=.true
 
 /* 
 make some buttons which have tasks assigned to them.
 */
 
 okButton= .button~new("OK",20,20,25)
 okButton~task=.goToWindowTask~new(win,1)
 
 
 okButton2= .button~new("OK",20,20,25)
 okButton2~task= .goToWindowTask~new(secondwin,0)
  
 print2= .button~new("Print to File",20,50,25)
 print2~task=.printAllFieldsToFile~new(secondwin)
  
 clearTask= .clearEntryTask~new(win)
 clearButton= .button~new("CLEAR",20,50,25)
 clearButton~task= cleartask

  
 /* add all the widgets to the windows */
 
menubar = .menu~new(wm) 
menuitem0 = .menuitem~new("Screen 1",.nil) 
menuitem1 = .menuitem~new("Screen 1", okButton~task)
menuitem2 = .menuitem~new("Screen 1", okButton2~task)
menuitem3 = .menuitem~new("Help" , helpwintask)
menubar~add(menuitem0)
menuitem0~add(menuitem1)
menuitem0~add(menuitem2)
menuitem0~add(menuitem3)

 
 /* the first window */
 
 win~add(label1)
 win~add(label2) 
 win~add(input1)
 win~add(input2)
 win~add(input3)
 win~add(input4)
 win~add(okButton)
 win~add(clearButton)
 win~add(fieldhelplabel)
 win~add(menubar)
 
 
 /* and the second window */
 
 secondwin~add(label1)
 secondwin~add(label2)
 secondwin~add(input1s2)
 secondwin~add(input2s2)
 secondwin~add(sliders2)
 secondwin~add(sliders2ro)
 secondwin~add(okButton2)
 secondwin~add(print2)
 secondwin~add(label3s2)
 secondwin~add(menubar)

 
  
 /* including something illegal here */
 wm~add("qaer") /* The system is effectively going to ignore this, treating it as a string against the WM */ 
 
 /*
  This is the population of the data management table with 
  the field objects, along with the lookup name 
  
  For a framework, the creation of a WMDMS service 
  seems somewhat counterintuitive, until you think of the common use cases. 
  This allows a single location, where one can   define criteria as to which fields must be completed, 
  which are are optional etc, and have the WM system understand the status of these. 
  Then  by virtue of setting up rules, validation is easier.  It also to act as a simple method to fetch 
  the current data values  of the fields, by name, to avoid having to programatically trawl through each window to identify 
  where a given field is.  In my experience, due to design changes, fields often move around screens, so having them all centrally 
  stored saves substantial time when refactoring, as it means that you don't have to change lots of code when you make minor layout changes
 */
 
 wmdms~put(input1,"input1")
 wmdms~put(input2,"input2")
 wmdms~put(input3,"input3")
 wmdms~put(input4,"input4")
 wmdms~put(input1S2,"input1S2")
 wmdms~put(input2S2,"input2S2")
 wmdms~put(sliders2,"slider2")
 wmdms~put(sliders2ro,"sliders2ro")
 
 /*
 create a virtual screen and add it to the wm 
 The purpose of a virtual screen is to allow you to lay out items based upon a 80x25 screen layout, 
 and have it adapt if the screen layout is running in a window, and therefore can change.  
 It should be noted that it does not change the size of widgets (as in, the length of them).  They are still "FIXED" size,
 but it adapts where they are placed on the screen in an attempt to ensure that they are reasonably sensibly placed.
 
 The code currently makes some attempts to try to deal with resizing of the display (window) during runtime, but the code 
 does not check for this event all the time, and as such, it can take a little while to adapt. 
 */
 vscreen = .VirtualScreen~new() 
 wm~add(vscreen)
 
 /*add windows to window manager along with two key activated tasks*/
 wm~add(win)
 wm~add(secondwin)
 
 /* 
 add the keyboard bound tasks to the window as well, in this case to go to screen 1 and screen 2
 */
 
 wm~add(task1)
 wm~add(task2)
 wm~add(helpwintask)
 wm~add(ProgTask)
 wm~add(helpwintask2)
 
 
 /* 
 add the data management serviec to the window manager 
 */
 wm~add(wmdms)
 
 /* run window manager */
 
 wm~run()

 /* once wm has stopped the following will run */
 
 wm~logger~log( "Window Manager is shutdown",1)

 
 
    do i = 1 to 3 
        say "shutdown " 
        call syssleep(1)
    end 

    /* 
        ensure that this thread dies by killing all rexx running, rather brutal but this is a test application isn't it.
    */
    wm~forceWMShutdown()

/* we are done */
exit




::requires "tui.cls" 

