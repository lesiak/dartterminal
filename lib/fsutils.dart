library fsutils;

import 'dart:html';
import 'dart:async';

class FileSystemUtils {
  
  static void ls(DirectoryEntry dir, successCallback) {     
      // Read contents of current working directory. According to spec, need to
      // keep calling readEntries() until length of result array is 0. We're
      // guarenteed the same entry won't be returned again.
      List<Entry> entries = [];
      /*var loudify = (msg) { 
        print(msg.toUpperCase()); 
      };*/
      var reader = dir.createReader();

      var readEntries;
      readEntries = () {
        reader.readEntries().then((List<Entry> results) {
          if (results.isEmpty) {
           // entries.sort();
            successCallback(entries);
          } else {
            entries.addAll(results);
            readEntries();
          }
        }, onError: _logFileError);
      };

      readEntries();
  }
  
  static Future read(DirectoryEntry dir, String path, successCallback) {
    Future readerFuture = dir.getFile(path).then((FileEntry fileEntry) {
          fileEntry.file().then((ff) {
            var reader = new FileReader();

            reader.onLoadEnd.first.then((e) {
              successCallback(reader.result);
            });

            reader.readAsText(ff);
          }, onError: _logFileError);
        });
    return readerFuture;
  }
  
  static void _logFileError(FileError e) {
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
  
}