part of terminal_impl;



class DartTerminalImpl {
  
  static const VERSION = '1.0.0';
  static const CMDS = const [
      'cat', 'cd', 'cp', 'clear', 'date', 'help', 'ls', 'mkdir',
      'mv', 'open', 'pwd', 'rm', 'rmdir', 'theme', 'version', 'wget'
    ];

  FileSystem fs;
  DirectoryEntry cwd;
  TerminalDisplay display;
  CommandHistory history = new CommandHistory();
  InputElement cmdLine;
  OutputElement output_;
  
  DartTerminalImpl(this.cmdLine, this.output_) {
      display = new TerminalDisplay(cmdLine, output_);
      int fsQuota = 5*1024*1024*1024;
      window.requestFileSystem(fsQuota, persistent: true)
                 .then((fs) => _requestFileSystemCallback(fs), onError: (e) => errorHandler(e));
      installEventHandlers();     
  }
  
  void installEventHandlers() {
    cmdLine.addEventListener('keydown', processNewCommand, false);
    cmdLine.addEventListener('keyup', historyHandler, false); // keyup needed for input blinker to appear at end of input.
    
    document.body.addEventListener('dragenter', (e) {
        e.stopPropagation();
        e.preventDefault();
        document.body.classes.add('dropping');
      }, false);

      document.body.addEventListener('dragover', (e) {
        e.stopPropagation();
        e.preventDefault();
        e.dataTransfer.dropEffect = 'copy'; // Explicitly show this is a copy.
      }, false);

      document.body.addEventListener('dragleave', (e) {
        document.body.classes.remove('dropping');
      }, false);
      
      document.body.addEventListener('drop', (e) {
        e.stopPropagation();
        e.preventDefault();
        document.body.classes.remove('dropping');
        addDroppedFiles(e.dataTransfer.files);
        display.outputHtml('<div>File(s) added!</div>');
      }, false);  
  }
  
  void _requestFileSystemCallback(FileSystem filesystem) {
    fs = filesystem;
    cwd = filesystem.root;   
  }


  void processNewCommand(KeyboardEvent e) {    
    String value = cmdLine.value;

       // Beep on backspace and no value on command line.
       //if (!value && e.keyCode == 8) {
         //bell_.stop();
         //bell_.play();
         //return;
      // }

       if (e.keyCode == 9) { // Tab
         e.preventDefault();
         // TODO(ericbidelman): Implement tab suggest.
       } else if (e.keyCode == 13) { // enter
         // Save shell history.
         if (value.isNotEmpty) {
           history.addNewItem(cmdLine.value);
         }
         
         display.duplicateInputToOutput();
        
        
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
           case 'cat':
             var fileName = args.join(' ');
             if (fileName.isEmpty) {
               output('usage: ' + cmd + ' filename');
               break;
             }
             catCommand(cmd, fileName);
             break;
           case 'clear':
             display.clear();
             return;
           case 'date':
             var now = new DateTime.now();           
             output(now.toString());
             break;
           case 'aaa':
                               
                 output('aaa<br/>');
                 output(cwd.fullPath + "<br/>");
                 output(cwd.toString() + "<br/>");
                 output(cwd.toUrl() + "<br/>");
                      break;   
           case 'help':
             output('<div class="ls-files">' + CMDS.join('<br>') + '</div>');
             output('<p>Add files by dragging them from your desktop.</p>');
             break;
           case 'ls':           
             ls_((List<Entry> entries) => display.displayEntries(entries));                                                
             break;
           case 'pwd':
             output(cwd.fullPath);
             break;
           case 'cd':
             String dest = args.isNotEmpty ? args.join(' ') : '';          
             cwd.getDirectory(dest).then((DirectoryEntry dirEntry) {
               cwd = dirEntry;
               output('<div>' + dirEntry.fullPath + '</div>');

               // Tell FSN visualizer that we're cd'ing.
               /*if (fsn_) {
                 fsn_.contentWindow.postMessage({cmd: 'cd', data: dest}, location.origin);
               }*/

             }, onError: (e) => invalidOpForEntryType(e, cmd, dest));

             break;
           case 'mkdir':
             var makeParents = false; // no error if existing, make parent directories as needed
             var index = args.indexOf('-p');
             if (index != -1) {
             //  args.splice(index, 1);
             //  makeParents = true;
               args.removeAt(index);             
               makeParents = true;
             }

             if (args.isEmpty) {
               output('usage: ' + cmd + ' [-p] directory<br>');
               break;
             }

             // Create each directory passed as an argument.
             args.forEach((dirName) => mkDir(dirName, makeParents, cmd));
             break;
           case 'cp':
           case 'mv':
             if (args.length < 2) {
               output(['usage: ', cmd, ' source target<br>',
                     '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;', cmd,
                     ' source directory/'].join(''));
              break; 
             }
             String src = args[0];
             String dest = args[1];

             
  /*
             var runAction = function(cmd, srcDirEntry, destDirEntry, opt_newName) {
               var newName = opt_newName || null;
               if (cmd == 'mv') {
                   srcDirEntry.moveTo(destDirEntry, newName);
                 } else {
                   srcDirEntry.copyTo(destDirEntry, newName);
                 }
             };
  */
             // Moving to a folder? (e.g. second arg ends in '/').
             if (dest[dest.length - 1] == '/') {
               cwd.getDirectory(src).then((DirectoryEntry srcDirEntry) {
                 // Create blacklist for dirs we can't re-create.
                 bool create = [
                   '.', './', '..', '../', '/'].indexOf(dest) != -1 ? false : true;
                 var cmd = create ? cwd.createDirectory : cwd.getDirectory;
                 

                 cmd(dest).then((destDirEntry) {
                   print('action dir to dir');
                   //runAction(cmd, srcDirEntry, destDirEntry);
                 }, onError: errorHandler);
               }, onError: (e) {
                 print('aaaaaaaaaaaaaaaaaaaaaaa');
                 // Try the src entry as a file instead.
                 /*cwd_.getFile(src, {}, function(srcDirEntry) {
                   cwd_.getDirectory(dest, {}, function(destDirEntry) {
                     runAction(cmd, srcDirEntry, destDirEntry);
                   }, onError: errorHandler);
                 }, onError: errorHandler);*/
               });
             } /*else { // Treat src/destination as files.
               cwd_.getFile(src, {}, function(srcFileEntry) {
                 srcFileEntry.getParent(function(parentDirEntry) {
                   runAction(cmd, srcFileEntry, parentDirEntry, dest);
                 }, errorHandler_);
               }, errorHandler_);
             }
  */
             break;
           case 'open':
             var fileName = args.join(' ');
             if (fileName.isEmpty) {
               output('usage: ' + cmd + ' filename');
               break;
             }
             openCommand(cmd, fileName);

             break;
    /*       case 'init':
             if (worker_) {
               worker_.postMessage({cmd: 'init', type: type_, size: size_});
             }
             break;*/
           case 'rm':
             // Remove recursively? If so, remove the flag(s) from the arg list.
             var recursive = false;
             ['-r', '-f', '-rf', '-fr'].forEach((arg) {
               var index = args.indexOf(arg);
               if (index != -1) {
                 args.removeAt(index);
                 recursive = true;
               }
             });
             // Remove each file passed as an argument.
             args.forEach((fileName) => rm(fileName, recursive, cmd));
             break;
           case 'rmdir':
             // Remove each directory passed as an argument.
             args.forEach((dirName) => rmDir(dirName, cmd));            
             break;        
           case 'theme':
             String theme = args.join(' ');
             themeCommand(theme, cmd);
             break;
           case 'version':
           case 'ver':
             output(VERSION);
             break;
           case 'wget':           
             if (args.isEmpty || args[0].trim().isEmpty) {
               output(['usage: ', cmd, ' missing URL'].join(''));
               break;
             } 
             var url = args[0].trim();
             if (!url.startsWith('http://')) {
               url = 'http://' + url;
             }
             wgetCommand(url);                     
             break;         
           case 'testunzip':
             String path = 'dupa.zip';
             testUnzip(path);
             break;
           default:
             if (cmd.isNotEmpty) {
               output(cmd + ': command not found');
             }
             
         };
        
         cmdLine.value = ''; // Clear/setup line for next input.
         
       
     }
  }


  void addDroppedFiles(files) {
    files.forEach((file) {
      cwd.createFile(file.name, exclusive: true).then((FileEntry fileEntry) {

            // Tell FSN visualizer we've added a file.
            //if (fsn_) {
//            fsn_.contentWindow.postMessage({cmd: 'touch', data: file.name}, location.origin);
    //        }
            
            fileEntry.createWriter().then((FileWriter fileWriter) {
              fileWriter.write(file);
            }, onError: errorHandler);
          }, onError: errorHandler);
        });
      }


  void output(String html) {
    display.outputHtml(html);
  }


  void ls_(successCallback) {
      if (fs == null) {
        return;
      }
      FileSystemUtils.ls(cwd, successCallback);
  }


  void rm(String name, bool recursive, String cmd) {
    cwd.getFile(name).then((Entry fileEntry) {
        fileEntry.remove().then((__x) {
          // Tell FSN visualizer that we're rm'ing.
         // if (fsn_) {
          //  fsn_.contentWindow.postMessage({cmd: 'rm', data: fileName}, location.origin);
         // }
        }, onError: errorHandler);
      }, onError: ((e) {
        if (recursive && e.code == FileError.TYPE_MISMATCH_ERR) {
          cwd.getDirectory(name).then((DirectoryEntry dirEntry) {
            dirEntry.removeRecursively().then((__x) {}, onError: errorHandler);
          }, onError: errorHandler);
        } else if (e.code == FileError.TYPE_MISMATCH_ERR) {
          output(cmd + ': ' + name + ': is a directory<br>');
        } else {
          errorHandler(e);
        }
    }));
  }

  void rmDir(String dirName, String cmd) {
    cwd.getDirectory(dirName).then((dirEntry) {
       dirEntry.remove().then((_x) {
         // Tell FSN visualizer that we're rmdir'ing.
         //if (fsn_) {
         //  fsn_.contentWindow.postMessage({cmd: 'rm', data: dirName}, location.origin);
        // }
       }, onError: (e) {
         if (e.code == FileError.INVALID_MODIFICATION_ERR) {
           output(cmd + ': ' + dirName + ': Directory not empty<br>');
         } else {
           errorHandler(e);
         }
       });
     }, onError: (e) { invalidOpForEntryType(e, cmd, dirName); });
  }

  void mkDir(String dirName, bool makeParents, String cmd){
    if (makeParents) {
       var folders = dirName.split('/');

       // Throw out './' or '/' if present on the beginning of our path.
       if (folders[0] == '.' || folders[0] == '') {
         folders = folders.sublist(1);
       }

       createDir_(cwd, folders);
     } else {
       cwd.createDirectory(dirName, exclusive: true).then((entry) {
         // Tell FSN visualizer that we're mkdir'ing.
         //if (fsn_) {
         //  fsn_.contentWindow.postMessage({cmd: 'mkdir', data: dirName}, location.origin);
        // }
       }, onError: (e) { invalidOpForEntryType(e, cmd, dirName); });
     }
  }

  void createDir_(DirectoryEntry rootDirEntry, List<String> folders) {  
    var fHead = folders[0];
    var fTail = folders.sublist(1);
    rootDirEntry.createDirectory(fHead).then((dirEntry) {

      // Recursively add the new subfolder if we still have a subfolder to create.
      if (fTail.isNotEmpty) {
        createDir_(dirEntry, fTail);
      }
    }, onError: errorHandler);
  }

  void openCommand(cmd, path) {
      if (fs == null) {
        return;
      }

      cwd.getFile(path).then((fileEntry) {
        var myWin = window.open(fileEntry.toUrl(), 'mywin');
      }, onError: (e) {
        if (e.code == FileError.NOT_FOUND_ERR) {
          output(cmd + ': ' + path + ': No such file or directory<br>');
        }
      });
    }


  void catCommand(cmd, path) {
    if (fs == null) {
      return;
    }    
    Future<String> textFuture = FileSystemUtils.readAsText(cwd, path);
    textFuture.then((s) {
      display.outputEscaped(s);
    }).catchError((e) {
      if (e.code == FileError.TYPE_MISMATCH_ERR) {
        output(cmd + ': ' + path + ': is a directory<br>');
      } else if (e.code == FileError.NOT_FOUND_ERR) {
        output(cmd + ': ' + path + ': No such file or directory<br>');
      }
    });
  }

  void testUnzip(String path) {     
    if (fs == null) {
      return;
    }    
    Future<List<int>> bytesFuture = FileSystemUtils.readAsArrayBuffer(cwd, path);
    bytesFuture.then((List<int> bytes) {    
      Archive archive = new ZipDecoder().decodeBytes(bytes);
      for (ArchiveFile file in archive) {
        String filename = file.name;
        output(filename);
        
        List<int> data = file.content;
        Blob blob = new Blob([data]);
        FileSystemUtils.saveBlob(cwd, filename, blob);
        
      }
    }).catchError((e) {
      /*if (e.code == FileError.TYPE_MISMATCH_ERR) {
        output(cmd + ': ' + path + ': is a directory<br>');
      } else if (e.code == FileError.NOT_FOUND_ERR) {
        output(cmd + ': ' + path + ': No such file or directory<br>');
      }*/
         
      errorHandler(e);
    });
  }

  void wgetCommand(String url) {
    HttpRequest.getString(url).then((String response) {
       output('<textarea>' + response + '</textarea>');
     }, onError: (ProgressEvent e) {             
       HttpRequest target = e.currentTarget;
       output('ERROR: ${target.status} ${target.statusText}');
     });    
  }

  void historyHandler(e) { // Tab needs to be keydown.    
    if (history.isNotEmpty) {
      if (e.keyCode == 38 || e.keyCode == 40) {
        bool isMoveUp = e.keyCode == 38;
        String newVal = history.changeLineVal(cmdLine.value, isMoveUp);
        cmdLine.value = newVal;
        cmdLine.value = cmdLine.value; // Sets cursor to end of input.
      }
    }      
  }

  void themeCommand(String theme, String cmd) {
    if (theme.isEmpty) {
       display.outputHtml(['usage: ', cmd, ' ' + TerminalDisplay.THEMES.join(',')].join(''));
     } else {
       //display.setTheme(theme);
       if (TerminalDisplay.THEMES.indexOf(theme) != -1) {
         display.setTheme(theme);
       } else {
         output('Error - Unrecognized theme used');
       }
     }  
  }


  void errorHandler(e) {
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
     };
     output('<div>Error: ' + msg + '</div>');
   }

  void invalidOpForEntryType(e, cmd, dest) {
     if (e.code == FileError.NOT_FOUND_ERR) {
       output(cmd + ': ' + dest + ': No such file or directory<br>');
     } else if (e.code == FileError.INVALID_STATE_ERR) {
       output(cmd + ': ' + dest + ': Not a directory<br>');
     } else if (e.code == FileError.INVALID_MODIFICATION_ERR) {
       output(cmd + ': ' + dest + ': File already exists<br>');
     } else {
       errorHandler(e);     
     }
   }
  
  
  
}
