/*
	Base class to override Array's default base with, so we can add these functions directly to arrays.
	
	Example usage:
		ary := ["a", "b"]
		MsgBox, % ary.join() ; Popup with "a,b" in it
*/

/*
	Functions to consider moving here
		insertFront
		arrayAppend
		arrayDropEmptyValues
	Functions to replace and remove
		getArraySize	=>	.count (built-in)
		arrayContains	=>	.contains
		
*/

class ArrayBase {
	contains(needle) { ; Returns index of FIRST instance found
		For index,element in this
			if(element = needle)
				return index
		return ""
	}
	
	removeDuplicates() {
		tempAry := []
		
		; Move everything over to a temporary array
		For _,val in this
			tempAry.push(val)
		this.removeAt(this.minIndex(), this.length()) ; GDB TODO turn this into a clear() function
		
		; Add only unique values back in
		For _,val in tempAry {
			if(!arrayContains(this, val)) ; GDB TODO replace this with .contains()
				this.push(val)
		}
	}
	
	join(delim := ",") {
		outString := ""
		
		For _,value in this {
			if(outString)
				outString .= delim
			outString .= value
		}
		
		return outString
	}
}