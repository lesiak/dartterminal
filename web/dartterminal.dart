import 'dart:html';
import 'package:dartterminal/fsutils.dart';
import 'package:dartterminal/terminal.dart';

void main() { 
  InputElement cmdLine = querySelector('#input-line .cmdline');
  int fsQuota = 5*1024*1024;
  window.requestFileSystem(fsQuota, persistent: true)
             .then((fs) => _requestFileSystemCallback(fs), onError: (e) => _logFileError(e));
  cmdLine.addEventListener('keydown', processNewCommand, false);
  cmdLine.addEventListener('keyup', historyHandler, false); // keyup needed for input blinker to appear at end of input.
}

void _requestFileSystemCallback(FileSystem filesystem) {
  fs = filesystem;
  cwd = filesystem.root;   
}

FileSystem fs;
DirectoryEntry cwd;


CommandHistory history = new CommandHistory();

void processNewCommand(KeyboardEvent e) {
//  print('aaa');
  /*function processNewCommand_(e) {*/
  OutputElement output_ =  querySelector('output');
  InputElement cmdLine = querySelector('#input-line .cmdline');
  String value = cmdLine.value;
//  int aaa = 0;
//  print('aaa');
     // Beep on backspace and no value on command line.
     //if (!value && e.keyCode == 8) {
       //bell_.stop();
       //bell_.play();
       //return;
    // }

     if (e.keyCode == 9) { // Tab
       e.preventDefault();
       // TODO(ericbidelman): Implement tab suggest.
     }  else if (e.keyCode == 13) { // enter

       // Save shell history.
       if (value.isNotEmpty) {
         history.addNewItem(cmdLine.value);
       }
       
      // Duplicate current input and append to output section.
       DivElement line = cmdLine.parentNode.parentNode.clone(true);      
       line.attributes.remove('id');
       line.classes.add('line');
       var input = line.querySelector('input.cmdline');
       input.autofocus = false;
       input.readOnly = true;
       output_.append(line);
      
       // Parse out command, args, and trim off whitespace.
       // TODO(ericbidelman): Support multiple comma separated commands.
       String cmd = "";
       List<String> args = [];
       if (value.isNotEmpty && value.trim().isNotEmpty) {
         //var args = value.split(' ').filter(function(val, i) {
         //  return val;
         //});
         args = value.split(' ');
         cmd = args[0].toLowerCase();
         //args = args.splice(1); // Remove cmd from arg list.
         args = args.sublist(1);
       }

       switch (cmd) {
         /*case '3d':
           clear_(this);
           output('Hold on to your butts!');
           toggle3DView_();
           break;
           */ 
         case 'cat':
           var fileName = args.join(' ');
           if (fileName.isEmpty) {
             output('usage: ' + cmd + ' filename');
             break;
           }
           read_(cmd, fileName, (result) {
            output('<pre>' + result + '</pre>');
           });         
           break;
        /* case 'clear':
           clear_(this);
           return;
         case 'date':
           output((new Date()).toLocaleString());
           break;
         case 'exit':
           if (is3D_) {
             toggle3DView_();
           }
           if (timer_ != null) {
             magicWord_.stop();
             clearInterval(timer_);
           }
           break;
         case 'help':
           output('<div class="ls-files">' + CMDS_.join('<br>') + '</div>');
           output('<p>Add files by dragging them from your desktop.</p>');
           break;
         case 'install':
           // Check is installed.
           if (window.chrome && window.chrome.app) {
             if (!window.chrome.app.isInstalled) {
               try {
                 chrome.app.install();
               } catch(e) {
                 alert(e + '\nEnable is about:flags');
               }
             } else {
               output('This app is already installed.');
             }
           }
           break;*/
         case 'ls':           
           ls_((List<Entry> entries) => displayEntries(entries));              
                       
           
           break;
         case 'pwd':
           output(cwd.fullPath);
           break;
         /*case 'cd':
           var dest = args.join(' ') || '/';

           cwd_.getDirectory(dest, {}, function(dirEntry) {
             cwd_ = dirEntry;
             output('<div>' + dirEntry.fullPath + '</div>');

             // Tell FSN visualizer that we're cd'ing.
             if (fsn_) {
               fsn_.contentWindow.postMessage({cmd: 'cd', data: dest}, location.origin);
             }

           }, function(e) { invalidOpForEntryType_(e, cmd, dest); });

           break;
         case 'mkdir':
           var dashP = false;
           var index = args.indexOf('-p');
           if (index != -1) {
             args.splice(index, 1);
             dashP = true;
           }

           if (!args.length) {
             output('usage: ' + cmd + ' [-p] directory<br>');
             break;
           }

           // Create each directory passed as an argument.
           args.forEach(function(dirName, i) {
             if (dashP) {
               var folders = dirName.split('/');

               // Throw out './' or '/' if present on the beginning of our path.
               if (folders[0] == '.' || folders[0] == '') {
                 folders = folders.slice(1);
               }

               createDir_(cwd_, folders);
             } else {
               cwd_.getDirectory(dirName, {create: true, exclusive: true}, function() {
                 // Tell FSN visualizer that we're mkdir'ing.
                 if (fsn_) {
                   fsn_.contentWindow.postMessage({cmd: 'mkdir', data: dirName}, location.origin);
                 }
               }, function(e) { invalidOpForEntryType_(e, cmd, dirName); });
             }
           });
           break;
         case 'cp':
         case 'mv':
           var src = args[0];
           var dest = args[1];

           if (!src || !dest) {
             output(['usage: ', cmd, ' source target<br>',
                    '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;', cmd,
                    ' source directory/'].join(''));
             break;
           }

           var runAction = function(cmd, srcDirEntry, destDirEntry, opt_newName) {
             var newName = opt_newName || null;
             if (cmd == 'mv') {
                 srcDirEntry.moveTo(destDirEntry, newName);
               } else {
                 srcDirEntry.copyTo(destDirEntry, newName);
               }
           };

           // Moving to a folder? (e.g. second arg ends in '/').
           if (dest[dest.length - 1] == '/') {
             cwd_.getDirectory(src, {}, function(srcDirEntry) {
               // Create blacklist for dirs we can't re-create.
               var create = [
                 '.', './', '..', '../', '/'].indexOf(dest) != -1 ? false : true;

               cwd_.getDirectory(dest, {create: create}, function(destDirEntry) {
                 runAction(cmd, srcDirEntry, destDirEntry);
               }, errorHandler_);
             }, function(e) {
               // Try the src entry as a file instead.
               cwd_.getFile(src, {}, function(srcDirEntry) {
                 cwd_.getDirectory(dest, {}, function(destDirEntry) {
                   runAction(cmd, srcDirEntry, destDirEntry);
                 }, errorHandler_);
               }, errorHandler_);
             });
           } else { // Treat src/destination as files.
             cwd_.getFile(src, {}, function(srcFileEntry) {
               srcFileEntry.getParent(function(parentDirEntry) {
                 runAction(cmd, srcFileEntry, parentDirEntry, dest);
               }, errorHandler_);
             }, errorHandler_);
           }

           break;
         case 'open':
           var fileName = args.join(' ');

           if (!fileName) {
             output('usage: ' + cmd + ' filename');
             break;
           }

           open_(cmd, fileName, function(fileEntry) {
             var myWin = window.open(fileEntry.toURL(), 'mywin');
           });

           break;
         case 'init':
           if (worker_) {
             worker_.postMessage({cmd: 'init', type: type_, size: size_});
           }
           break;
         case 'rm':
           // Remove recursively? If so, remove the flag(s) from the arg list.
           var recursive = false;
           ['-r', '-f', '-rf', '-fr'].forEach(function(arg, i) {
             var index = args.indexOf(arg);
             if (index != -1) {
               args.splice(index, 1);
               recursive = true;
             }
           });

           // Remove each file passed as an argument.
           args.forEach(function(fileName, i) {
             cwd_.getFile(fileName, {}, function(fileEntry) {
               fileEntry.remove(function() {
                 // Tell FSN visualizer that we're rm'ing.
                 if (fsn_) {
                   fsn_.contentWindow.postMessage({cmd: 'rm', data: fileName}, location.origin);
                 }
               }, errorHandler_);
             }, function(e) {
               if (recursive && e.code == FileError.TYPE_MISMATCH_ERR) {
                 cwd_.getDirectory(fileName, {}, function(dirEntry) {
                   dirEntry.removeRecursively(null, errorHandler_);
                 }, errorHandler_);
               } else if (e.code == FileError.INVALID_STATE_ERR) {
                 output(cmd + ': ' + fileName + ': is a directory<br>');
               } else {
                 errorHandler_(e);
               }
             });
           });
           break;
         case 'rmdir':
           // Remove each directory passed as an argument.
           args.forEach(function(dirName, i) {
             cwd_.getDirectory(dirName, {}, function(dirEntry) {
               dirEntry.remove(function() {
                 // Tell FSN visualizer that we're rmdir'ing.
                 if (fsn_) {
                   fsn_.contentWindow.postMessage({cmd: 'rm', data: dirName}, location.origin);
                 }
               }, function(e) {
                 if (e.code == FileError.INVALID_MODIFICATION_ERR) {
                   output(cmd + ': ' + dirName + ': Directory not empty<br>');
                 } else {
                   errorHandler_(e);
                 }
               });
             }, function(e) { invalidOpForEntryType_(e, cmd, dirName); });
           });
           break;         
         case 'theme':
           var theme = args.join(' ');
           if (!theme) {
             output(['usage: ', cmd, ' ' + THEMES_.join(',')].join(''));
           } else {
             if (THEMES_.indexOf(theme) != -1) {
               setTheme_(theme);
             } else {
               output('Error - Unrecognized theme used');
             }
           }
           break;
         case 'version':
         case 'ver':
           output(VERSION_);
           break;
         case 'wget':
           var url = args[0];
           if (!url) {
             output(['usage: ', cmd, ' missing URL'].join(''));
             break;
           } else if (url.search('^http://') == -1) {
             url = 'http://' + url;
           }
           var xhr = new XMLHttpRequest();
           xhr.onload = function(e) {
             if (this.status == 200 && this.readyState == 4) {
               output('<textarea>' + this.response + '</textarea>');
             } else {
               output('ERROR: ' + this.status + ' ' + this.statusText);
             }
           };
           xhr.onerror = function(e) {
             output('ERROR: ' + this.status + ' ' + this.statusText);
             output('Could not fetch ' + url);
           };
           xhr.open('GET', url, true);
           xhr.send();
           break;
         case 'who':
           output(document.title +
                  ' - By: Eric Bidelman &lt;ericbidelman@chromium.org&gt;');
           break;*/
         default:
           if (cmd.isNotEmpty) {
             output(cmd + ': command not found');
           }
           
       };
      
       cmdLine.value = ''; // Clear/setup line for next input.
       
     
   }
}

void displayEntries(List<Entry> entries) {
  if (entries.isNotEmpty) {
    List<String> html = formatColumns_(entries);    
    Iterable<String> sa = entries.map((Entry entry) => 
        '<span class="' 
        + ( entry.isDirectory ? 'folder' : 'file' )
        +'">'
        + entry.name
        + '</span><br>'
    ); 
    html.addAll(sa);
    html.add('</div>');
    output(html.join(''));
     /*var html = formatColumns_(entries);
     util.toArray(entries).forEach(function(entry, i) {
       html.push(
           '<span class="', entry.isDirectory ? 'folder' : 'file',
           '">', entry.name, '</span><br>');
     });
     html.push('</div>');
     output(html.join(''));
   }*/
  }    
}

void output(String html) {
  InputElement cmdLine = querySelector('#input-line .cmdline');
  OutputElement output_ =  querySelector('output');
  output_.insertAdjacentHtml('beforeEnd', html);       
  cmdLine.scrollIntoView();
 }

void ls_(successCallback) {
    if (fs == null) {
      return;
    }
    FileSystemUtils.ls(cwd, successCallback);

 
}

List<String> formatColumns_(List<Entry> entries) {
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

void read_(cmd, path, successCallback) {
    if (fs == null) {
      return;
    }

    cwd.getFile(path).then((FileEntry fileEntry) {
      fileEntry.file().then((ff) {
        var reader = new FileReader();

        reader.onLoadEnd.first.then((e) {
          successCallback(reader.result);
        });

        reader.readAsText(ff);
      }, onError: _logFileError);
    }, onError: (e) {
      if (e.code == FileError.INVALID_STATE_ERR) {
        output(cmd + ': ' + path + ': is a directory<br>');
      } else if (e.code == FileError.NOT_FOUND_ERR) {
        output(cmd + ': ' + path + ': No such file or directory<br>');
      }
    });
  }

void historyHandler(e) { // Tab needs to be keydown.
  InputElement cmdLine = querySelector('#input-line .cmdline');
  if (history.isNotEmpty) {
    if (e.keyCode == 38 || e.keyCode == 40) {
      bool isMoveUp = e.keyCode == 38;
      String newVal = history.changeLineVal(cmdLine.value, isMoveUp);
      cmdLine.value = newVal;
      cmdLine.value = cmdLine.value; // Sets cursor to end of input.
    }
  }
  
    /*if (history.isNotEmpty) {
      if (e.keyCode == 38 || e.keyCode == 40) {
        if (history[histpos]!= null) {
          history[histpos] = cmdLine.value;
        } else {
         histtemp = cmdLine.value;
        }
      }

      if (e.keyCode == 38) { // up
        histpos--;
        if (histpos < 0) {
          histpos = 0;
        }
      } else if (e.keyCode == 40) { // down
        histpos++;
        if (histpos > history.length) {
          histpos = history.length;
        }
      }

      if (e.keyCode == 38 || e.keyCode == 40) {
        cmdLine.value = history[histpos] != null ? history[histpos] : histtemp;
        cmdLine.value = cmdLine.value; // Sets cursor to end of input.
      }
    }*/
  }

void _logFileError(FileError e) {
     var msg = '';
     switch (e.code) {
       case FileError.QUOTA_EXCEEDED_ERR:
         msg = 'QUOTA_EXCEEDED_ERR';
         break;
       case FileError.NOT_FOUND_ERR:
         msg = 'NOT_FOUND_ERR';
         break;
       case FileError.SECURITY_ERR:
         msg = 'SECURITY_ERR';
         break;
       case FileError.INVALID_MODIFICATION_ERR:
         msg = 'INVALID_MODIFICATION_ERR';
         break;
       case FileError.INVALID_STATE_ERR:
         msg = 'INVALID_STATE_ERR';
         break;
       default:
         msg = 'Unknown Error';
         break;
     }
     print("Error: $msg");
   }