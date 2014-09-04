
import 'dart:html';
import 'package:dartterminal/terminal_impl.dart';


void main() {
  InputElement cmdLine = querySelector('#input-line .cmdline');
  OutputElement output_ =  querySelector('output');
  DartTerminalImpl dt = new DartTerminalImpl(cmdLine, output_);
  
}

