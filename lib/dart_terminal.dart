import 'package:polymer/polymer.dart';
import 'package:dartterminal/terminal_impl.dart';
import 'dart:html';

/**
 * A Polymer click counter element.
 */
@CustomTag('dart-terminal-new')
class DartTerminalNew extends PolymerElement {
  @published int count = 0;

  DartTerminalNew.created() : super.created() {    
    InputElement cmdLine = shadowRoot.querySelector('#input-line .cmdline');
    OutputElement output_ =  shadowRoot.querySelector('output');
    DartTerminalImpl dt = new DartTerminalImpl(cmdLine, output_);
  }

  void increment() {
    count++;
  }
}


