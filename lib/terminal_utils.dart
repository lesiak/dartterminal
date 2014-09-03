library terminal_utils;

class CommandHistory {
  Map<int, String> history = {};
  int histpos = 0;
  String histtemp = "";
  
  void addNewItem(String item) {
    history[histpos] = item;         
    histpos = history.length;
  }
  
  bool get isNotEmpty => history.isNotEmpty;
  
  String changeLineVal(String curVal, bool isMoveUp) {
    //InputElement cmdLine = querySelector('#input-line .cmdline');
    if (history.isNotEmpty) {
         
         if (history[histpos]!= null) {
           history[histpos] = curVal;
         } else {
           histtemp = curVal;
         }
         
         if (isMoveUp) { // up
           histpos--;
           if (histpos < 0) {
             histpos = 0;
           }
         } else { // down
           histpos++;
           if (histpos > history.length) {
             histpos = history.length;
           }
         }

         return history[histpos] != null ? history[histpos] : histtemp;
         //cmdLine.value = history[histpos] != null ? history[histpos] : histtemp;
         //cmdLine.value = cmdLine.value; // Sets cursor to end of input.
         
       }
      return curVal;
  }
  
  String moveDown(String curVal) {
    return changeLineVal(curVal, false);
  }
  
  String moveUp(String curVal) {
      return changeLineVal(curVal, true);
    }
  
}
