/* ---------------------------------------------------------------- */
/* To and from ooRexx to JSON and vice versa                        */
/* ---------------------------------------------------------------- */
/*                                                                  */
/* Originally by Brandon Cherry                                     */                                                            
/*                                                                  */
/* Via discussion here:                                             */
/*    https://groups.google.com/forum/#!topic/comp.lang.rexx/e8cZJEkAzcs/discussion */
/*                                                                  */
/* Copied from:                                                     */
/*    http://learning.safedataisp.net/ajax/json.cls                 */
/*                                                                  */
/* Please keep this comment block intact when modifying this code   */
/* and add a note with date and a description.                      */
/*                                                                  */
/* ---------------------------------------------------------------- */
/*  2011/12/31 - Or so copied from above site  - Ruurd J. Idenburg  */
/* ---------------------------------------------------------------- */
/* As it can no longer be found at the original location I have now */
/* dragged the code into my own source base for another experiment  */

::class json public /* RFC 4627 */

/**
 * Initilizes the class
 */
::method init
    expose eJS uJS whitespace ctrl

    eJS = .directory~new() -- escape Javascript
    eJS['08'x] = '\b'
    eJS['09'x] = '\t'
    eJS['0A'x] = '\n'
    eJS['0C'x] = '\f'
    eJS['0D'x] = '\r'
    eJS['"'] = '\"'
    eJS['\'] = '\\'
    eJS['/'] = '\/'

    uJS = .directory~new() -- unescape Javascript
    do index over eJS
        uJS[eJS[index]] = index
    end

    whitespace = .set~new() -- allowed whitespace chars
    whitespace[] = '09'x
    whitespace[] = '0A'x
    whitespace[] = '0D'x
    whitespace[] = ' '

    ctrl = whitespace~copy() -- chars that end a value
    ctrl[] = '}'
    ctrl[] = ']'
    ctrl[] = ','

/**
 * Converts a rexx object to JSON formatting to pass to eval()
 *
 * @param  rexxObject   The object to converts directory, array,
 *                      or string objects. Otherwise, it calls
 *                      the makearray method for the object.
 */
::method toJSON
    expose buffer
    use arg rexxObject

    buffer = .mutablebuffer~new()
    self~parseRexxObject(rexxObject)
return buffer~string

::method parseRexxObject private
    expose buffer
    use arg rexxObject

    select
        when .array~id == rexxObject~class~id then do
            self~parseRexxArray(rexxObject)
        end
        when .directory~id == rexxObject~class~id then do
            self~parseRexxDirectory(rexxObject)
        end
        when .string~id == rexxObject~class~id then do
            self~parseRexxString(rexxObject)
        end
        when .nil == rexxObject then do
            buffer~append('null')
        end
        otherwise
            if rexxObject~hasMethod('makearray') then do
                self~parseRexxObject(rexxObject~makearray())
            end
            else buffer~append('null')
    end

::method parseRexxArray private
    expose buffer
    use arg rexxObject

    buffer~append('[')
    if rexxObject~items() == 0 then buffer~append(']')
    else do
        do item over rexxObject
            self~parseRexxObject(item)
            buffer~append(',')
        end
        buffer~overlay(']', buffer~length)
    end

::method parseRexxDirectory private
    expose buffer
    use arg rexxObject

    buffer~append('{')
    if rexxObject~items == 0 then buffer~append('}')
    else do
        do index over rexxObject -- index in JSON must be a quoted string
            if .string~id == index~class~id then self~parseRexxString(index, .true)
            else buffer~append('"'index~class'"')
            buffer~append(':')
            self~parseRexxObject(rexxObject[index])
            buffer~append(',')
        end
        buffer~overlay('}', buffer~length)
    end

::method parseRexxString private
    expose buffer eJS
    use arg rexxObject

    if rexxObject~length == 0 then buffer~append('""')
    else do
        if rexxObject~dataType('n') then do
            if arg(2, 'e') then buffer~append('"'rexxObject'"')
            else buffer~append(rexxObject)
        end
        else do
            buffer~append('"')
            do i = 1 to rexxObject~length
                char = rexxObject~substr(i, 1)
                if eJS~hasIndex(char) then buffer~append(eJS[char])
                else buffer~append(char)
            end
            buffer~append('"')
        end
    end

/**
 * Recursively converts a json string to rexx objects
 *
 * @param  jsonString   A json string.
 */
::method fromJSON
    expose jsonString jsonPos jsonStringLength
    signal on user parseError
    use arg jsonString

    jsonPos = 1
    jsonStringLength = jsonString~length
    self~trimLeadingWhitespace()
    rexxObject = self~parseJSONvalue()
    if jsonPos >= jsonStringLength then return rexxObject
    else do
        self~trimLeadingWhitespace()
        if jsonPos >= jsonStringLength then return rexxObject
        message = 'Expected end of input'
        signal extraChars
    end
return .nil

parseError:
    c = condition('o')
    message = c['ADDITIONAL'][1]
extraChars:
    raise syntax 3.900 array(message 'at' jsonString~substr(jsonPos, 25))
return .nil

/**
 * Determines type of value.
 *
 */
::method parseJSONvalue private
    expose jsonString jsonPos
    signal on user parseError

    parse value jsonString with =(jsonPos) char +1
    select
        when char == '{' then do
            jsonPos = jsonPos + 1
            return self~parseJSONobject()
        end
        when char == '[' then do
            jsonPos = jsonPos + 1
            return self~parseJSONarray()
        end
        when char == '"' then do
            jsonPos = jsonPos + 1
            return self~parseJSONstring()
        end
        otherwise return self~parseJSONother()
    end
return
parseError: raise propagate

/**
 * Converts a json object into a rexx directory object.
 *
 */
::method parseJSONobject private
    expose jsonString jsonPos
    signal on user parseError

    rexxDirectory = .directory~new()

    parse value jsonString with =(jsonPos) char +1
    if char == '}' then do
        jsonPos = jsonPos + 1
        return rexxDirectory
    end
    else self~parseJSONobjectValue(rexxDirectory)

    do forever
        self~trimLeadingWhitespace()
        parse value jsonString with =(jsonPos) char +1
        select
            when char == '}' then do
                jsonPos = jsonPos + 1
                return rexxDirectory
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONobjectValue(rexxDirectory)
            end
            otherwise raise user parseError array('Expected end of an object or new value')
        end
    end
return
parseError: raise propagate

/**
 * Converts json name:value pairs into a rexx directory item@index.
 *
 * @param  rexxDirectory   A rexx directory object.
 */
::method parseJSONobjectValue private
    expose jsonString jsonPos
    signal on user parseError
    use arg rexxDirectory

    self~trimLeadingWhitespace()
    parse value jsonString with =(jsonPos) char +1
    if char == '"' then do
        jsonPos = jsonPos + 1
        index = self~parseJSONstring()
    end
    else raise user parseError array('Name must be a quoted string')

    self~trimLeadingWhitespace()
    parse value jsonString with =(jsonPos) char +1
    if char == ':' then do
        jsonPos = jsonPos + 1
        self~trimLeadingWhitespace()
        rexxDirectory[index] = self~parseJSONvalue()
    end
    else raise user parseError array('Expected colon separating object name and value')
return
parseError: raise propagate

/**
 * Converts a json array into a rexx array object.
 *
 */
::method parseJSONarray private
    expose jsonString jsonPos
    signal on user parseError

    rexxArray = .array~new()

    parse value jsonString with =(jsonPos) char +1
    if char == ']' then do
        jsonPos = jsonPos + 1
        return rexxArray
    end
    else self~parseJSONarrayValue(rexxArray)

    do forever
        self~trimLeadingWhitespace()
        parse value jsonString with =(jsonPos) char +1
        select
            when char == ']' then do
                jsonPos = jsonPos + 1
                return rexxArray
            end
            when char == ',' then do
                jsonPos = jsonPos + 1
                self~parseJSONarrayValue(rexxArray)
            end
            otherwise raise user parseError array('Expected end of an array or new value')
        end
    end
return
parseError: raise propagate

/**
 * Converts a json array values into rexx array items.
 *
 * @param  rexxArray   A rexx array object.
 */
::method parseJSONarrayValue private
    expose jsonString
    signal on user parseError
    use arg rexxArray

    self~trimLeadingWhitespace()
    index = rexxArray~last
    if .nil == index then index = 0
    rexxArray[index + 1] = self~parseJSONvalue()
return
parseError: raise propagate

/**
 * Converts a quoted json string into a rexx string object.
 *
 */
::method parseJSONstring private
    expose jsonString uJS jsonPos jsonStringLength
    signal on user parseError

    rexxString = .mutablebuffer~new()
    do forever
        parse value jsonString with =(jsonPos) char +1
        if char == '\' then do
            parse value jsonString with =(jsonPos) char2 +2
            if uJS~hasIndex(char2) then do
                jsonPos = jsonPos + 2
                rexxString~append(uJS[char2])
            end
            else do
                jsonPos = jsonPos + 1
                rexxString~append(char)
            end
        end
        else do
            jsonPos = jsonPos + 1
            if char == '"' then return rexxString~string
            else rexxString~append(char)
        end
        if jsonPos >= jsonStringLength then raise user parseError array('Expected end of a quoted string')
    end
return
parseError: raise propagate

/**
 * Converts other json types into rexx objects.
 *
 */
::method parseJSONother private
    expose jsonString ctrl jsonPos jsonStringLength
    signal on user parseError

    length = jsonStringLength + 1
    do i = jsonPos while i \== length
        parse value jsonString with =(i) char +1
        if ctrl~hasIndex(char) then leave
    end
    parse value jsonString with =(jsonPos) string +(i - jsonPos)
    if string~datatype('n') then do
        jsonPos = jsonPos + string~length
        return string
    end
    else do
        select
            when string == 'false' then do
                jsonPos = jsonPos + string~length
                return .false
            end
            when string == 'true' then do
                jsonPos = jsonPos + string~length
                return .true
            end
            when string == 'null' then do
                jsonPos = jsonPos + string~length
                return .nil
            end
            otherwise nop
        end
    end
raise user parseError array('Invalid JSON value')
return
parseError: raise propagate

/**
 * Removes allowed whitespace between values.
 *
 */
::method trimLeadingWhitespace private
    expose jsonString whitespace jsonPos jsonStringLength

    do while jsonPos \== jsonStringLength
        parse value jsonString with =(jsonPos) char +1
        if whitespace~hasIndex(char) then jsonPos = jsonPos + 1
        else leave
    end


