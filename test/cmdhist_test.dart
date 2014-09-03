import 'package:unittest/unittest.dart';
import 'package:dartterminal/terminal_utils.dart';
import 'package:unittest/html_config.dart';

main() {
  useHtmlConfiguration();
  group('Command History:', () {
    test('one command and up', () {
      CommandHistory hist = new CommandHistory();  
      hist.addNewItem("val1");
      String curVal = '';
      curVal = hist.moveUp(curVal);
      expect(curVal, equals("val1"));
    });
    
    test('commandUpUp', () {
      CommandHistory hist = new CommandHistory();  
        hist.addNewItem("val1");
        String curVal = '';  
        curVal = hist.moveUp(curVal);
        curVal = hist.moveUp(curVal);
        expect(curVal, equals("val1"));
    });
    
    test('commandUpDown', () {
      CommandHistory hist = new CommandHistory();  
        hist.addNewItem("val1");
        String curVal = '';  
        curVal = hist.moveUp(curVal);
        curVal = hist.moveDown(curVal);
        expect(curVal, equals(''));
     });
    
    test('2commandsModifyFirst', () {
          CommandHistory hist = new CommandHistory();  
            hist.addNewItem("val1");
            hist.addNewItem("val2");
            String curVal = '';  
            curVal = hist.moveUp(curVal);
            curVal = hist.moveUp(curVal);
            curVal = 'modifiedVal';
            curVal = hist.moveDown(curVal);
            curVal = hist.moveUp(curVal);
            expect(curVal, equals('modifiedVal'));
    });
    
    test('DownWithModifiedVal', () {
      CommandHistory hist = new CommandHistory();  
      hist.addNewItem("val1");      
      String curVal = 'modifiedVal';  
      curVal = hist.moveDown(curVal);      
      expect(curVal, equals('modifiedVal'));
     });
        
        
    
  });
}

