/* 

    Example of use of mixin class to set attributes on the fly 
    

*/

    dog = .DynamicAttributeDataType~new("FIDO") 
    dog~setpaws(4)
    say dog~paws  /* prints 4  */ 
    say dog~getpaws  /* also prints 4  */ 
    dog~paws= 3 /* poor fido */
    dog~noise = "bow wow" 
    say dog dog~getpaws() dog~getNoise /* now prints FIDO 3 bow wow */

    cat1 = .DynamicAttributeDataType~new("PUSSY") 
    cat1~setpaws(4)
    say cat1~paws  /* prints 4  */ 
    say cat1~getpaws  /* also prints 4  */ 
    cat1~paws= 3 /* looks like fido and Pussy both got off badly  */
    cat1~noise = "bow wow" /* we're suffering some confusion here */ 
    say cat1 cat1~getpaws() cat1~noise /* now prints PUSSY 3 bow wow */
    
    
    cat2 = .DynamicAttributeDataType~new("PUSSY")  /* some people are really unimaginative  */
    cat2~setpaws(4)
    say cat2~paws  /* prints 4  */ 
    cat2~noise = "miow"  /* finally we make some sense */ 
    say cat2 cat2~getpaws() cat2~noise /* now prints PUSSY 4 miow */
    say cat2~colour /* .nil */ 




exit 

::requires "dadt.cls" 
