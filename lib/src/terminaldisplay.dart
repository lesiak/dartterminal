part of terminal_impl;

class TerminalDisplay {
  
  static const THEMES = const ['default', 'cream'];
  
  InputElement cmdLine;
  OutputElement output_;
  
  TerminalDisplay(this.cmdLine, this.output_);
  
  void duplicateInputToOutput() {    
    DivElement line = cmdLine.parentNode.parentNode.clone(true);      
    line.attributes.remove('id');
    line.classes.add('line');
    var input = line.querySelector('input.cmdline');
    input.autofocus = false;
    input.readOnly = true;
    output_.append(line);
  }
  
  void outputHtml(String html) {    
    output_.insertAdjacentHtml('beforeEnd', html);       
    cmdLine.scrollIntoView();
  }
  
  
  void outputEscaped(String htmlText) {
      String result = HTML_ESCAPE.convert(htmlText);
      outputHtml('<pre>' + result + '</pre>');
    }

  void clear() {
    output_.setInnerHtml('');
    cmdLine.value = '';
    document.documentElement.style.height = '100%';
    // interlace_.style.height = '100%';
   }
  
  void displayEntries(List<Entry> entries) {
    if (entries.isNotEmpty) {
      List<String> html = _formatColumns(entries);    
      Iterable<String> sa = entries.map((Entry entry) => 
          '<span class="' 
          + ( entry.isDirectory ? 'folder' : 'file' )
          +'">'
          + entry.name
          + '</span><br>'
      ); 
      html.addAll(sa);
      html.add('</div>');
      outputHtml(html.join(''));     
    }    
  }
  
  void setTheme(String theme) {
      //var currentUrl = document.location.pathname;

      if (theme.isEmpty || theme == 'default') {
        //history.replaceState({}, '', currentUrl);
        window.localStorage.remove('theme');
        document.body.className = '';
        return;
      }

      if (theme.isNotEmpty) {
        document.body.classes.add(theme);
        window.localStorage['theme'] = theme;
        //history.replaceState({}, '', currentUrl + '#theme=' + theme);
      }
    }

  
  List<String> _formatColumns(List<Entry> entries) {
    var maxName = entries[0].name;
    entries.forEach((entry) {
      if (entry.name.length > maxName.length) {
        maxName = entry.name;
      }
    });
    
    // If we have 3 or less entries, shorten the output container's height.
    // 15px height with a monospace font-size of ~12px;
    var height = entries.length == 1 ? 'height: ' + (entries.length * 30).toString() + 'px;' :
                 entries.length <= 3 ? 'height: ' + (entries.length * 18).toString() + 'px;' : '';

    // ~12px monospace font yields ~8px screen width.
    var colWidth = maxName.length * 16;//;8;

    return ['<div class="ls-files" style="-webkit-column-width:',
            colWidth, 'px;', height, '">'];
  }

}