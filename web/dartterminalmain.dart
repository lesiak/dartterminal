
import 'dart:html';
import 'package:dartterminal/terminal.dart';


void main() {
  InputElement cmdLine = querySelector('#input-line .cmdline');
  OutputElement output_ =  querySelector('output');
  DartTerminal dt = new DartTerminal(cmdLine, output_);
  
}

