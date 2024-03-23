     /*-                                                                            +
      * Copyright (c) 2001-2018 Scott C. Klement                                    +
      * All rights reserved.                                                        +
      *                                                                             +
      * Redistribution and use in source and binary forms, with or without          +
      * modification, are permitted provided that the following conditions          +
      * are met:                                                                    +
      * 1. Redistributions of source code must retain the above copyright           +
      *    notice, this list of conditions and the following disclaimer.            +
      * 2. Redistributions in binary form must reproduce the above copyright        +
      *    notice, this list of conditions and the following disclaimer in the      +
      *    documentation and/or other materials provided with the distribution.     +
      *                                                                             +
      * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ''AS IS'' AND      +
      * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE       +
      * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE  +
      * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE     +
      * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL  +
      * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS     +
      * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)       +
      * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT  +
      * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY   +
      * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF      +
      * SUCH DAMAGE.                                                                +
      *                                                                             +
      */                                                                            +

      /if defined(HTTPAPI_H)
      /eof
      /endif

     D HTTPAPI_VERSION...
     D                 C                   CONST('1.39')
     D HTTPAPI_RELDATE...
     D                 C                   CONST('2018-03-09')

      /copy *LIBL/qrpglesrc,config_h


      *********************************************************************
      **  procedure prototypes
      *********************************************************************

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  HTTP_req(): Perform any HTTP request and get input/output from
      *              either a string or an IFS stream file.
      *
      *        Type = (input)  request type (POST, GET, PUT, DELETE, etc)
      *         URL = (input)  URL to make request to
      *  ResultStmf = (input)  IFS path to stream file to store response
      *                        (file is replaced) or *OMIT to use ResultStr
      *      -or-
      *   ResultStr = (output) String in which to store response. Pass
      *                        *OMIT to use ResultStmf
      *
      * -- only for POST/PUT requests: --
      *    SendStmf = (input)  When doing a PUT/POST type request, pass
      *                        this to specify a file (IFS stream file)
      *                        to send as the request body document,
      *                        or *OMIT to use SendStmf
      *      -or-
      *    SendStr  = (input)  If SendStmf=*OMIT, use this to pass a string
      *                        to use as the request body document.
      * ContentType = (input)  The content-type (MIME type) of data you
      *                        are sending. Pass *OMIT for the default.
      *
      *  Returns  -1 for local-detected error
      *            0 for communications timed out
      *            1 for success
      *        2-999 for HTTP server provided error code
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_req        PR            10i 0 opdesc
     D   Type                        10a   varying const
     D   URL                      32767a   varying const
     D   ResultStmf                5000a   varying const
     D                                     options(*varsize:*omit)
     D   ResultStr                     a   len(16000000) varying
     D                                     options(*varsize:*omit:*nopass)
     D   SendStmf                  5000a   varying const
     D                                     options(*varsize:*omit:*nopass)
     D   SendStr                       a   len(16000000) varying const
     D                                     options(*varsize:*omit:*nopass)
     D   ContentType              16384A   varying const
     D                                     options(*varsize:*omit:*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  HTTP(): Perform any HTTP request using a flexible "reader/writer"
      *          approach.
      *
      *       Method = (input) HTTP method to use in the request
      *          URL = (input) URL to make request to
      *       Writer = (input) writer utility that will save the result
      *       Reader = (input) reader utility that will read the data to send
      *
      *  Sends an exception method upon error. (call http_error for details)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http            PR
     D   Method                      10a   varying const
     D   URL                      32767a   varying const
     D   Writer                        *   const
     D   Reader                        *   const
     D                                     options(*nopass:*omit)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_setOption():  Sets an HTTP option used on subsequent requests
      *
      *   option = (input) option string to set
      *    value = (input) value of option string
      *
      * possible options are:
      *
      * 'timeout' = numeric value.  If this many seconds pass without
      *             any network activity, the request is aborted.
      *
      * 'soap-action' = Value to be placed in the HTTP "soap-action" header
      *             used when calling web services with the SOAP protocol
      *
      * 'content-type' = When uploading a stream in a POST or PUT request,
      *             this specifies the data type you're sending
      *
      * 'user-agent' = overrides the user-agent string sent to the HTTP
      *             server. This allows you to test servers that require a
      *             particular browser (such as IE or Chrome)
      *
      * '100-timeout' = time to wait for a '100 Continue' response when
      *             sending a request body (such as a POST/PUT request).
      *             Value should be a number of seconds.
      *
      * 'use-cookies' = indicates whether cookie support in HTTPAPI is
      *             enabled or not.  Value should be '1' for enabled or
      *             '0' for disabled.
      *
      * 'local-ccsid' = CCSID to use for your local machine when text data
      *             needs to be translated.  Value should be a number from
      *             1-65533 or the special value '0' for "current job ccsid".
      *             Usually this is some form of EBCDIC.
      *
      * 'network-ccsid' = CCSID to to use for the data sent over the network
      *             to remote sites.  Value should be a number from 1-65533.
      *             Typically this should be 1208 (UTF-8) or for older sites,
      *             some form of ASCII.
      *
      * 'file-ccsid' = When a new file is created in the IFS, HTTPAPI will
      *             assign this CCSID. Value should be a number from 1-65533.
      *             HTTPAPI does not use this to translate the data, it only
      *             puts this in the file description.
      *
      * 'file-mode' = When a new file is created in the IFS, HTTPAPI will
      *             use this parameter as the file's "mode" (authorities).
      *             Value should be a number, same as the 3rd parameter to
      *             the IFS open() API.
      *
      * 'debug-level' = Number indicating the amount of detail written to
      *             the debug/trace file that httpapi creates when you use
      *             the http_debug(*on) feature.  1=Normal, 2=Mode Detailed
      *
      * 'if-modified-since' = value should be a timestamp in *ISO char
      *                  format.  On a GET request, the file will only
      *                  be retrieved if it has changed since this date/time.
      *
      *returns 0 if successful, -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_setOption  PR            10i 0
     D    option                     32a   varying const
     D    value                   65535a   varying const
     D                                     options(*varsize)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  HTTP_string(): Perform any HTTP request using short strings
      *
      *     NOTE: For longer strings, use HTTP_req().
      *
      *        Type = (input)  request type (POST, GET, PUT, DELETE, etc)
      *         URL = (input)  URL to make request to
      *
      * -- only for POST/PUT requests: --
      *    SendStr  = (input)  String to send (for requests like POST
      *                         or PUT.)
      * ContentType = (input)  The content-type (MIME type) of data you
      *                        are sending. Pass *OMIT for the default.
      *
      *  NOTE: To pass options such as the content-type, user agent,
      *        timeout, or soap action, use http_setOption().
      *
      *  Returns the response body as a string.
      *       or sends an *ESCAPE message upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_string     PR        100000a   varying
     D   Type                        10a   varying const
     D   URL                      32767a   varying const
     D   SendStr                 100000a   varying const
     D                                     options(*varsize:*omit:*nopass)
     D   ContentType              16384A   varying const
     D                                     options(*varsize:*omit:*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  HTTP_stmf(): Perform any HTTP request using stream files
      *
      *        Type = (input) request type (POST, GET, PUT, DELETE, etc)
      *         URL = (input) URL to make request to
      *    RespStmf = (input) Stream (IFS) file to store data into
      *
      * -- only for POST/PUT requests: --
      *    SendStmf = (input) Stream (IFS) file containing data to send
      *                         for PUT or POST requests
      * ContentType = (input)  The content-type (MIME type) of data you
      *                        are sending. Pass *OMIT for the default.
      *
      *  NOTE: To pass options such as the content-type, user agent,
      *        timeout, or soap action, use http_setOption().
      *
      *  Returns the output into the RespStmf,
      *       or sends an *ESCAPE message upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D  http_stmf      PR
     D   Type                        10a   varying const
     D   URL                      32767a   varying const
     D   RespStmf                  5000a   varying const options(*varsize)
     D   SendStmf                  5000a   varying const
     D                                     options(*varsize:*omit:*nopass)
     D   ContentType              16384A   varying const
     D                                     options(*varsize:*omit:*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_get(): Retrieve an HTTP document
      *  http_url_get(): Retrieve an HTTP document
      *
      *       peURL = url to access (i.e. http://www.blah.com/dir/file.txt)
      *  peFilename = filename in IFS to save response into
      *  peTimeout  = (optional) give up if no data is received for
      *          this many seconds.
      *  peModTime  = (optional) only get file if it was changed since
      *          this timestamp. Provide *OMIT to disable this.
      *  peReserved = (optional) Not used. Pass *OMIT for this.
      *  peUserAgent = (optional) Designates the type of HTTP client
      *          to the server. Used to fake the server into thinking
      *          you are a different client (like Internet Explorer)
      *          Pass *OMIT if you don't need this.
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  -1 = error discovered by HTTPAPI
      *            0 = timeout while receiving data or connecting
      *            1 = file retrieved successfully
      *          > 1 = HTTP response code indicating server's error reply
      *
      *  For any error, call http_error() to get the error message
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_get        PR            10I 0 extproc('HTTP_URL_GET')
     D  peURL                     32767A   varying const options(*varsize)
     D  peFilename                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peReserved                16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)

     D http_url_get    PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  peFilename                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_url_post(): Post data to CGI script and get document
      *
      *         peURL = URL to post to (http://www.blah.com/cgi-bin/etc)
      *    pePostData = pointer to data (request body document) to send.
      *                 NOTE: Data pointed to by pePostData will be
      *                       translated to the remote (usually ASCII)
      *                       set via the pePostRem/pePostLoc values
      *                       of the http_setCCSIDs() routine.
      * pePostDataLen = length of data to post to CGI script.
      *   peFileName  = Filename in IFS to save response into
      *    peTimeout  = (optional) give up if no data is received for
      *            this many seconds.
      * peUserAgent = (optional) User-Agent string passed to the
      *            server. Used to make the server think you are a
      *            different client (like IE).  Pass *OMIT for default
      * peContentType = (optional) content type (MIME type) of the
      *            document you are sending.
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  -1 = error detected internally by HTTPAPI
      *            0 = timeout while receiving data or connecting
      *            1 = file retrieved successfully
      *          > 1 = HTTP response code indicating server's error reply
      *
      *  For any error, call http_error() to get the error message
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_post       PR            10I 0 EXTPROC('HTTP_URL_POST')
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peFilename                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
     D http_url_post   PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peFilename                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_url_get_raw(): Retrieve an HTTP document (in raw mode)
      *
      *       peURL = url to access (i.e. http://www.blah.com/dir/file.txt)
      *       peFD  = FD to pass back to peProc
      *     peProc  = procedure to call as data is received over the
      *               network.  It should be prototyped like this:
      *
      *        D incoming        PR            10i 0
      *        D   fd                          10i 0 value
      *        D   data                     65535a   options(*varsize)
      *        D   len                         10i 0 value
      *
      *  peTimeout  = (optional) give up if no data is received for
      *          this many seconds.
      * peUserAgent = (optional) User-Agent string passed to the
      *            server. Used to make the server think you are
      *            a different client (like IE). Pass *OMIT for
      *            if you don't need this.
      *  peModTime  = (optiona) only get file if it was changed since
      *          this timestamp. Pass *OMIT if you don't need this.
      *  peReserved = (optional) This is not used. Pass *OMIT
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  (same as http_url_get)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_get_raw...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  peFD                         10I 0 value
     D  peProc                         *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peReserved                   64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peReserved                16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_url_post_raw(): Post data to CGI script and get document
      *
      *         peURL = url to post to (http://www.blah.com/cgi-bin/etc)
      *    pePostData = pointer to data to send (request body document)
      *                 NOTE: Data pointed to by pePostData will be
      *                       translated to the remote (usually ASCII)
      *                       set via the pePostRem/pePostLoc values
      *                       of the http_setCCSIDs() routine.
      * pePostDataLen = length of data to post to CGI script.
      *          peFD = FD to pass back to peProc
      *        peProc = procedure to call each time data arrives on the
      *                 network.  It should be prototype liked this:
      *
      *        D incoming        PR            10i 0
      *        D   fd                          10i 0 value
      *        D   data                     65535a   options(*varsize)
      *        D   len                         10i 0 value
      *
      *    peTimeout  = (optional) give up if no data is received for
      *            this many seconds.
      *  peUserAgent  = (optional) User-Agent string passed to the
      *            server. Pass *OMIT if you don't need this.
      * peContentType = (optional) content type (MIME type) of the
      *            document you're sending. Pass *OMIT for default.
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  (same as http_url_post)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_post_raw...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peFD                         10I 0 value
     D  peProc                         *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_url_post_raw2(): Post data to CGI script and get document
      *
      *         peURL = url to post to (http://www.blah.com/cgi-bin/etc)
      *      pePostFD = descriptor number to pass to pePostProc
      *    pePostProc = Subprocdure that HTTPAPI calls in order to
      *                 get the data (request body document) to be sent
      *                 to the server.
      *         NOTE: HTTPAPI considers data sent via the
      *               pePostProc to be "binary". If you want
      *               it translated, please do so in your program.
      *     peDataLen = total length of data that will be sent.
      *      peSaveFD = FD to pass back to peSaveProc
      *    peSaveProc = procedure to call each time data is received.
      *    peTimeout  = (optional) give up if no data is received for
      *            this many seconds.
      * peUserAgent = (optional) User-Agent string passed to the
      *            server. Use *OMIT for default value
      * peContentType = (optional) content type (MIME type) to identify
      *            your data to the server. Use *OMIT for default
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns (same as http_url_post)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_post_raw2...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFD                     10I 0 value
     D  pePostProc                     *   procptr value
     D  peDataLen                    10I 0 value
     D  peSaveFD                     10I 0 value
     D  peSaveProc                     *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_url_post_stmf(): Post data to CGI script from stream file
      *
      *         peURL = url to post to (http://www.blah.com/cgi-bin/etc)
      *    pePostFile = Filename (in IFS) of file to send to http server
      *                   (request body document)
      *    peRecvFile = Filename (in IFS) of stream file containing reply
      *                   (response body document)
      *    peTimeout  = (optional) give up if no data is received for
      *            this many seconds.
      * peUserAgent = (optional) User-Agent string passed to the
      *            server. Pass *OMIT for the default
      * peContentType = (optional) content type (MIME type) to supply
      *            to the server. Pass *OMIT for default.
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns (same as http_url_post)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_post_stmf...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFile                32767A   varying const options(*varsize)
     D  peRecvFile                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif
     D http_post_stmf  PR            10I 0 extproc('HTTP_URL_POST_STMF')
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFile                32767A   varying const options(*varsize)
     D  peRecvFile                32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_get_xml();
      * http_url_get_xml():  Send a GET request to an HTTP server and
      *     send the response document through an XML parser.
      *
      *       peURL = (input) URL to perform GET request to
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed to the
      *                    call-back routine
      *
      * (other parms are identical to those in HTTP_url_get())
      *
      * peStartProc should point to a procedure with a procedure
      * interface that's compatable with the following:
      *
      *  D StartProc       PR
      *  D   userdata                      *   value
      *  D   depth                       10I 0 value
      *  D   name                      1024A   varying const
      *  D   path                     24576A   varying const
      *  D   attrs                         *   dim(32767)
      *  D                                     const options(*varsize)
      *
      * peEndProc should point to a procedure with a procedure
      * interface that's compatable with the following:
      *
      *  D EndProc         PR
      *  D   userdata                      *   value
      *  D   depth                       10I 0 value
      *  D   name                      1024A   varying const
      *  D   path                     24576A   varying const
      *  D   value                    32767A   varying const
      *  D   attrs                         *   dim(32767)
      *  D                                     const options(*varsize)
      *
      *  Returns (same as http_url_get)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_get_xml...
     D                 PR            10I 0 EXTPROC('HTTP_URL_GET_XML')
     D  peURL                     32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
     D http_url_get_xml...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_post_xml();
      * http_url_post_xml():  Send a POST request to an HTTP server and
      *     receive/parse an XML response.
      *
      *          peURL = (input) URL to perform GET request to
      *     pePostData = (input) data to POST to the web server
      *  pePostDataLen = (input) length of pePostData
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *       peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *
      * (other parms are identical to those in HTTP_url_post())
      *
      * peStartProc should point to a procedure with a procedure
      * interface that's compatable with the following:
      *
      *  D StartProc       PR
      *  D   userdata                      *   value
      *  D   depth                       10I 0 value
      *  D   name                      1024A   varying const
      *  D   path                     24576A   varying const
      *  D   attrs                         *   dim(32767)
      *  D                                     const options(*varsize)
      *
      * peEndProc should point to a procedure with a procedure
      * interface that's compatable with the following:
      *
      *  D EndProc         PR
      *  D   userdata                      *   value
      *  D   depth                       10I 0 value
      *  D   name                      1024A   varying const
      *  D   path                     24576A   varying const
      *  D   value                    32767A   varying const
      *  D   attrs                         *   dim(32767)
      *  D                                     const options(*varsize)
      *
      *  Returns 1 if successful, -1 upon error, 0 if timeout
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_post_xml...
     D                 PR            10I 0 EXTPROC('HTTP_URL_POST_XML')
1    D  peURL                     32767A   varying const options(*varsize)
2    D  pePostData                     *   value
3    D  pePostDataLen                10I 0 value
4    D  peStartProc                    *   value procptr
5    D  peEndProc                      *   value procptr
6    D  peUsrDta                       *   value
7    D  peTimeout                    10I 0 value options(*nopass)
8    D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
9    D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
     D http_url_post_xml...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_post_stmf_xml();
      *  http_url_post_stmf_xml(): Post data to CGI script from stream file
      *        and receive/parse an XML response
      *
      *       peURL = (input) URL to post to
      *  pePostFile = (input) File of stream file (in IFS) to post
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *  peTimeout  = (optional) give up if no data is received for
      *                       this many seconds.
      * peUserAgent = (optional) User-Agent string passed to the
      *            server.  Pass the named constant HTTP_USERAGENT
      *            if you want to get the default value.
      * peContentType = (optional) content type to supply (mainly
      *                       useful when talking to CGI scripts)
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  -1 upon failure, 0 upon timeout,
      *            1 for success, or an HTTP response code
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_post_stmf_xml...
     D                 PR            10I 0 extproc('HTTP_URL_POST_STMF_XML')
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFile                32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
     D http_url_post_stmf_xml...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFile                32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_get_xmltf(): Request URL from server. Receive response
      *        to temporary file, then parse it.
      *
      *  NOTE: This routine is provided for backward compatibility ONLY
      *        please use http_get_xml() instead!
      *
      *       peURL = (input) URL to perform GET request to
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed to the
      *                    call-back routine
      *
      * (other parms are identical to those in HTTP_url_get())
      *
      *  Returns 1 if successful, -1 upon error, 0 if timeout
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_get_xmltf...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_post_xmltf(): Post data from memory. Receive
      *        response to temporary file, then parse it.
      *
      *  NOTE: This routine is provided for backward compatibility ONLY
      *        please use http_post_xml() instead!
      *
      *          peURL = (input) URL to perform GET request to
      *     pePostData = (input) data to POST to the web server
      *  pePostDataLen = (input) length of pePostData
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *       peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *
      * (other parms are identical to those in HTTP_url_post())
      *
      *  Returns 1 if successful, -1 upon error, 0 if timeout
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_post_xmltf...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_post_stmf_xmltf(): Post data from stream file.  Receive
      *        response to temporary file, then parse it.
      *
      *  NOTE: This routine is provided for backward compatibility ONLY
      *        please use http_post_stmf_xml() instead!
      *
      *       peURL = (input) URL to post to
      *  pePostFile = (input) File of stream file (in IFS) to post
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *  peTimeout  = (optional) give up if no data is received for
      *                       this many seconds.
      * peContentType = (optional) content type to supply (mainly
      *                       useful when talking to CGI scripts)
      *  peSOAPAction = (optional) string used to specify the action
      *          taken by some SOAP applications.
      *          - pass *blanks to send an empty SoapAction.
      *          - pass *omit (or don't pass the parm at all) if
      *             you don't want a SoapAction header to be sent.
      *
      *  Returns  -1 upon failure, 0 upon timeout,
      *            1 for success, or an HTTP response code
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_post_stmf_xmltf...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFile                32767A   varying const options(*varsize)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_error():   Return the last error that occurred.
      *
      *     peErrorNo = (optional) error number that occurred.
      *    peRespCode = (optional) HTTP response code (if applicable)
      *
      *  Returns the human-readable error message.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_error      PR            80A
     D   peErrorNo                   10I 0 options(*nopass:*omit)
     D   peRespCode                  10i 0 options(*nopass:*omit)


      /if defined(HAVE_SSLAPI)

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * https_init():  Initialize https (HTTP over SSL/TLS) protocol
      *
      *     peAppID = This parameter controls how HTTPAPI associates
      *               itself with the Digital Certificate Manager.
      *               a) If you pass *BLANKS, HTTPAPI will use the
      *                   default settings for the *SYSTEM cert store
      *                   (This option most closely resembles what a
      *                    browser would do -- and is the default.)
      *               b) If you pass a string containing the / character
      *                   HTTPAPI will consider this an IFS pathname to
      *                   a keyring file. (Only use this if you know
      *                   what you're doing.)
      *               c) In any other case, HTTPAPI will consider it an
      *                   application ID, and will use that application
      *                   profile from the "Manage Applications" section
      *                   of the Digital Certificate Manager. (Recommended
      *                   for high-security situations.)
      *
      *     peSSLv2 = (optional) Turn SSL version 2 *ON/*OFF  (default OFF)
      *     peSSLv3 = (optional) Turn SSL version 3 *ON/*OFF  (default OFF)
      *    peTLSv10 = (optional) Turn TLS version 1.0 *ON/*OFF (default ON)
      *    peTLSv11 = (optional) Turn TLS version 1.1 *ON/*OFF (default ON)
      *    peTLSv12 = (optional) Turn TLS version 1.2 *ON/*OFF (default ON)
      *
      *  If any of the SSL/TLS flags, above, are not passed then the default
      *  values will be used.
      *
      * Returns -1 upon failure.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_init      PR            10I 0
     D  peAppID                     100A   const
     D  peSSLv2                       1N   const options(*nopass)
     D  peSSLv3                       1N   const options(*nopass)
     D  peTLSv10                      1N   const options(*nopass)
     D  peTLSv11                      1N   const options(*nopass)
     D  peTLSv12                      1N   const options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * https_certStore(): Access an alternate certificate store
      *
      *     KdbPath = (input) Path to .KDB file for certificate store
      *                        or *CLEAR to unset alternate cert store
      * KdbPassword = (input) password for the certificate store
      *    KdbLabel = (input) Certificate label associated with the cert
      *
      * Call this API before using SSL functionality to associate your
      * job with the alternate certificate store.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_certStore...
     D                 PR
     D  KdbPath                    5000a   varying const
     D  KdbPassword                 256a   varying const
     D  KdbLabel                   5000a   varying const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  Register your application with the Digital Certificate Manager
      *
      *    peAppID = application ID.  IBM recommends that you do
      *         something like:  COMPANY_COMPONENT_NAME
      *         (example:  QIBM_DIRSRV_REPLICATION)
      *
      *  peLimitCA = set to *On if you want to only want to allow the
      *         certificate authorities registered in D.C.M., or set to
      *         *Off if you'll manage that yourself.
      *
      *   returns 0 for success, or -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_dcm_reg   PR            10I 0
     D  peAppID                     100A   const
     D  peLimitCA                     1N   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * https_cleanup():  Clean up & free storage used by the SSL
      *   environment.
      *
      *  returns 0 if successful, -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_cleanup   PR            10I 0


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * https_idname(): Returns a string that describes an SSL certificate
      *                  data element id (for printing/debugging)
      *
      *       peID = (input) data ID to get name of
      *
      * Returns the human-readable name
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_idname    PR            50A   varying
     D   peID                        10I 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * https_strict(): Force SSL to be strictly validated
      *
      *      peSetting = (input) *ON  = use full validation
      *                          *OFF = use passthru validation
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D https_strict    PR
     D   peSetting                    1n   const

      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_getauth():   Get HTTP Authentication Information
      *
      *   Call this proc after you receive a HTTP_NDAUTH error
      *   to determine the authentication credentials that are required
      *
      *  The following parms are returned to your program:
      *
      *     peBasic = *ON if BASIC auth is allowed
      *    peDigest = *ON if MD5 DIGEST auth is allowed
      *     peRealm = Auth realm.  Present this to the user to identify
      *               which password you're looking for.  For example
      *               if peRealm is "secureserver.com" you might say
      *               "enter password for secureserver.com" to user.
      *      peNTLM = *ON if NTLM auth is allowed
      *
      *   After getting the userid & password from the user (or database)
      *   you'll need to call http_setauth()
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_getauth    PR            10I 0
     D   peBasic                      1N
     D   peDigest                     1N
     D   peRealm                    124A
     D   peNTLM                       1N   options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_setauth():   Set HTTP Authentication Information
      *
      *  NOTE: Most sites that use userid/password use HTTP_AUTH_BASIC.
      *        Call this prior to any HTTP POST/GET/REQ routine.
      *
      *     peAuthType = Authentication Type (HTTP_AUTH_BASIC,
      *                     HTTP_AUTH_MD5_DIGEST, or HTTP_AUTH_NTLM)
      *     peUsername = UserName to use
      *     pePasswd   = Password to use
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_setauth    PR            10I 0
     D   peAuthType                   1A   const
     D   peUsername                  80A   const
     D   pePasswd                  1024A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_setproxy(): Set HTTP Proxy Address
      *
      *     peHost = Proxy host name
      *     psPort = Proxy port
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_setproxy   PR            10I 0
     D   peHost                     256A   const
     D   pePort                      10I 0 const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_proxy_setauth(): Set HTTP Proxy Authentication Information
      *
      *     peAuthType = Authentication Type (HTTP_AUTH_NONE or
      *                     HTTP_AUTH_BASIC)
      *     peUsername = UserName to use
      *     pePasswd   = Password to use
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_proxy_setauth...
     D                 PR            10I 0
     D   peAuthType                   1A   const
     D   peUsername                  80A   const
     D   pePasswd                  1024A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_proxy_getauth():   Get HTTP Proxy Authentication Information
      *
      *   Call this proc after you receive a HTTP_PXNDAUTH error
      *   to determine the authentication credentials that are required
      *
      *  The following parms are returned to your program:
      *
      *     peBasic = *ON if BASIC auth is allowed
      *     peRealm = Auth realm.  Present this to the user to identify
      *               which password you're looking for.  For example
      *               if peRealm is "secureproxy.com" you might say
      *               "enter password for secureproxy.com" to user.
      *
      *   After getting the userid & password from the user (or database)
      *   you'll need to call http_proxy_setauth()
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_proxy_getauth...
     D                 PR            10I 0
     D   peBasic                      1N
     D   peRealm                    124A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_xproc():  Register a procedure to be called back at
      *                 a given exit point
      *
      *     peExitPoint = exit point.  Should be one of the constants
      *                HTTP_POINT_XXX defined in the HTTPAPI_H member
      *          peProc = address of procedure to call for this
      *                exit point. (pass *NULL to disable this point)
      *      peUserData = Pointer to user data. This will be passed
      *                to your call-back procedure. You can set it to
      *                *NULL if you don't need/want it.
      *
      *  Returns -1 upon error, or 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_xproc      PR            10I 0
     D  peExitPoint                  10I 0 value
     D  peProc                         *   procptr value
     D  peUserData                     *   value options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_redir_loc(): Retrieve location provided by a redirect
      *   request.
      *
      *  returns redirect location, or '' if no redirect was given
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_redir_loc  PR          1024A   varying


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_urlEncode(): Encodes one component of a URL without
      *                   having to build a whole "form"
      *
      *   input = (input) string to encode
      *
      * Returns the encoded string, or '' upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_urlEncode  PR         65535a   varying
     D    input                        *   value options(*string)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_new():  Create a URL encoder.
      *
      *   returns an (opaque) pointer to the new encoder
      *           or *NULL upon error.
      *
      * WARNING: To free the memory used by this routine, you MUST
      *          call http_url_encoder_free() after the data is sent.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_URL_ENCODER...
     D                 s               *
     D http_url_encoder_new...
     D                 PR                  like(HTTP_URL_ENCODER)
      /if defined(WEBFORMS)
     D WEBFORM         s                   like(HTTP_URL_ENCODER)
     D WEBFORM_open    PR                  ExtProc('HTTP_URL_ENCODER_NEW')
     D                                     like(HTTP_URL_ENCODER)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_addvar():  Add a variable to what's stored
      *          a URL encoder.
      *
      *    peEncoder = pointer to encoder created by the
      *                  http_url_encoder_new() routine
      *   peVariable = variable name to add
      *       peData = pointer to data to store in variable
      *   peDataSize = size of data to store in variable
      *
      * Returns *ON if successful, *OFF otherwise.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_encoder_addvar...
     D                 PR             1N   extproc('HTTP_URL_ENCODER_-
     D                                     ADDVAR_LONG')
     D    peEncoder                    *   value
     D    peVariable                   *   value options(*string)
     D    peData                       *   value options(*string)
     D    peDataSize                 10i 0 value
      /if defined(WEBFORMS)
     D WEBFORM_setPtr...
     D                 PR             1N   extproc('HTTP_URL_ENCODER_-
     D                                     ADDVAR_LONG')
     D    peEncoder                    *   value
     D    peVariable                   *   value options(*string)
     D    peData                       *   value options(*string)
     D    peDataSize                 10i 0 value
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_getptr(): Get a pointer to the encoded
      *        data stored in a URL encoder
      *
      *     peEncoder = (input) pointer to encoder
      *        peData = (output) pointer to encoded data
      *        peSize = (output) size of encoded data
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_encoder_getptr...
     D                 PR
     D    peEncoder                        like(HTTP_URL_ENCODER) value
     D    peData                       *
     D    peSize                     10I 0
      /if defined(WEBFORMS)
     D WEBFORM_postData...
     D                 PR                  ExtProc('HTTP_URL_ENCODER_GETPTR')
     D    peEncoder                        like(WEBFORM) value
     D    peData                       *
     D    peSize                     10I 0
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_getstr(): Get encoded data he encoded
      *        data stored in a URL encoder as a string
      *
      *     peEncoder = (input) pointer to encoder
      *
      * NOTE: This routine is much slower than http_url_encoder_getptr()
      *       and is limited to a 32k return value.  It's suitable for
      *       use with data that's added to a URL, such as when
      *       performing a GET request to a web server, but you should
      *       use http_url_encoder_getptr() for POST requests.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_encoder_getstr...
     D                 PR         32767A   varying
     D    peEncoder                        like(HTTP_URL_ENCODER) value
      /if defined(WEBFORMS)
     D WEBFORM_getData...
     D                 PR         32767A   varying
     D                                     ExtProc('HTTP_URL_ENCODER_GETSTR')
     D    peEncoder                        like(WEBFORM) value
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_free(): free resources allocated by both
      *        http_url_encoder_new() and http_url_encoder_addvar()
      *
      *     peEncoder = pointer to encoder to free
      *
      * Returns *ON if successful, *OFF otherwise.
      *
      * WARNING: After calling this, do not use the encoder or
      *          data returned by http_url_encoder_getptr() again.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_encoder_free...
     D                 PR             1N
     D    peEncoder                        like(HTTP_URL_ENCODER) value
      /if defined(WEBFORMS)
     D WEBFORM_close...
     D                 PR             1N   ExtProc('HTTP_URL_ENCODER_FREE')
     D    peEncoder                        like(WEBFORM) value
      /endif

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_url_encoder_addvar_s():  Simplified (but limited)
      *       interface to http_url_encoder_addvar().
      *
      *    peEncoder = (input) HTTP_url_encoder object
      *   peVariable = (input) variable name to set
      *      peValue = (input) value to set variable to
      *
      * Returns *ON if successful, *OFF otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_url_encoder_addvar_s...
     D                 PR             1N   extproc('HTTP_URL_ENCODER_-
     D                                     ADDVAR_LONG_S')
     D    peEncoder                    *   value
     D    peVariable                   *   value options(*string)
     D    peValue                      *   value options(*string)
      /if defined(WEBFORMS)
     D WEBFORM_setVar...
     D                 PR             1N   extproc('HTTP_URL_ENCODER_-
     D                                     ADDVAR_LONG_S')
     D    peEncoder                    *   value
     D    peVariable                   *   value options(*string)
     D    peValue                      *   value options(*string)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_mfd_encoder_open(): Create a multipart/form-data encoder
      *
      * A multipart/form-data encoder will encode the variables
      * and or stream files that you pass to it and store the results
      * in a stream file.  You can later POST those results with the
      * http_url_post_stmf() API.
      *
      *     peStmFile = (input) pathname to stream file to store
      *                 encoded results.
      *
      * peContentType = (output) Type of this MFD form. Pass
      *                 this to the HTTP POST/PUT routine that
      *                 sends this data.
      *
      *   returns an (opaque) pointer to the new encoder
      *           or *NULL upon error.
      *
      * WARNING: To free the memory used by this routine and close
      *          the stream file, you MUST call http_mfd_encoder_close()
      *          after the data is sent.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_mfd_encoder_open...
     D                 PR              *
     D  peStmFile                      *   value options(*string)
     D  peContType                   64A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_mfd_encoder_addvar():  Add a variable to what's stored
      *          a multipart/form-data encoder.
      *
      *    peEncoder = pointer to encoder created by the
      *                  http_mfd_encoder_open() routine
      *   peVariable = variable name to add
      *       peData = pointer to data to store in variable
      *   peDataSize = size of data to store in variable
      *
      * Returns *ON if successful, *OFF otherwise.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_mfd_encoder_addvar...
     D                 PR             1N
     D    peEncoder                    *   value
     D    peVariable                 50A   varying value
     D    peData                       *   value
     D    peDataSize                 10I 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_mfd_encoder_addvar_s():  Simplified (but limited)
      *       interface to http_mfd_encoder_addvar().
      *
      *    peEncoder = (input) HTTP_mfd_encoder object
      *   peVariable = (input) variable name to set
      *      peValue = (input) value to set variable to
      *
      * Returns *ON if successful, *OFF otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_mfd_encoder_addvar_s...
     D                 PR             1N
     D    peEncoder                    *   value
     D    peVariable                 50A   varying value
     D    peValue                   256A   varying value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_mfd_encoder_addstmf(): Add a stream file to what's stored
      *       in a multipart/form-data encoder.
      *
      *    peEncoder = pointer to encoder created by the
      *                  http_mfd_encoder_open() routine
      *   peVariable = variable name to add
      *   pePathName = Path name of stream file to add
      *   peContType = Content-type of stream file to add
      *
      * Returns *ON if successful, *OFF otherwise.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_mfd_encoder_addstmf...
     D                 PR             1N
     D    peEncoder                    *   value
     D    peVariable                 50A   varying value
     D    pePathName                   *   value options(*string)
     D    peContType                 64A   varying const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_mfd_encoder_close():  close an open multipart/form-data
      *                            encoder.
      *
      *     peEncoder = (input) encoder to close
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_mfd_encoder_close...
     D                 PR
     D  peEncoder                      *   value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_persist_open(): Open a persistent HTTP session
      *
      *       peURL = url to connect to
      *  peTimeout  = (optional) give up if no data is received for
      *          this many seconds.
      *
      *  Returns *NULL upon failure, or
      *          pointer to HTTP communication session
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist_open...
     D                 PR              *
     D  peURL                     32767A   varying const options(*varsize)
     D  peTimeout                    10I 0 value options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_persist_get(): Get a file using a persistent HTTP session
      *
      *         peComm = (input) pointer to persistent HTTP comm session
      *          peURL = (input) URL to get from persistent HTTP
      *           peFD = (input) FD to pass back to peProc
      *         peProc = (input) procedure to call each time data is
      *                          received.
      *      peTimeout = (input/optional) time-out when no data is received
      *                          for this many seconds.
      *    peUserAgent = (optional) User-Agent string passed to the
      *                          server.  Pass the named constant called
      *                          HTTP_USERAGENT if you want to get the
      *                          default value.
      *      peModTime = (input/optional) only get file if it was changed
      *                          since this timestamp.
      *  peContentType = (input/optional) content type to supply (mainly
      *                          useful when talking to CGI scripts)
      *  peSOAPAction = (optional) string used to specify the action
      *                          taken by some SOAP applications.
      *                - pass *blanks to send an empty SoapAction.
      *                - pass *omit (or don't pass the parm at all) if
      *                    you don't want a SoapAction header to be sent.
      *
      *  Returns  1 if successful,
      *           0 if timed out
      *          -1 if an internal error occurs
      *          or an HTTP response code if an error comes from the server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist_get...
     D                 PR            10I 0
     D  peComm                         *   value
     D  peURL                     32767A   varying const options(*varsize)
     D  peFD                         10I 0 value
     D  peProc                         *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_persist_post(): Post data to CGI script and get document
      *                       using a persistent connection
      *
      *         peComm = (input) pointer to persistent HTTP comm session
      *          peURL = (input) URL to post to with persistent HTTP
      * --------
      *       pePostFD = (input) Opaque integer to pass to pePostProc
      *     pePostProc = (input) Pointer to call-back procedure for
      *                          posting data to server.  If you pass
      *                          *NULL for this, you should use pePostData
      *                          instead.
      *         NOTE: HTTPAPI considers data sent via the
      *               pePostProc to be "binary". If you want
      *               it translated, please do so in your program.
      * -- or --
      *     pePostData = (input) Pointer to data to post.  If you pass
      *                          *NULL for this, you should use pePostProc
      *                          instead.
      *         NOTE: HTTPAPI will translate the data in pePostData
      *               according to the values set in the pePostRem/pePostLoc
      *               parameters to http_setCCSIDs.
      * --------
      *  pePostDataLen = (input) Total length, in bytes, of post data.
      *       peSaveFD = (input) Opaque integer passed to peSaveProc
      *     peSaveProc = (input) Pointer to call-back procedure that is
      *                          called when data is received from HTTP
      *                          server.
      *      peTimeout = (input/optional) time-out when no data is received
      *                          for this many seconds.
      *    peUserAgent = (optional) User-Agent string passed to the
      *                          server.  Pass the named constant called
      *                          HTTP_USERAGENT if you want to get the
      *                          default value.
      *  peContentType = (input/optional) content type to supply (mainly
      *                          useful when talking to CGI scripts)
      *  peSOAPAction = (optional) string used to specify the action
      *                          taken by some SOAP applications.
      *                - pass *blanks to send an empty SoapAction.
      *                - pass *omit (or don't pass the parm at all) if
      *                    you don't want a SoapAction header to be sent.
      *
      *  Returns  1 if successful,
      *           0 if timed out
      *          -1 if an internal error occurs
      *          or an HTTP response code if an error comes from the server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist_post...
     D                 PR            10I 0
     D  peComm                         *   value
     D  peURL                     32767A   varying const options(*varsize)
     D  pePostFD                     10I 0 value
     D  pePostProc                     *   value procptr
     D  pePostData                     *   value
     D  pePostDataLen                10I 0 value
     D  peSaveFD                     10I 0 value
     D  peSaveProc                     *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
      /if defined(HTTP_ORIG_SHORTFIELD)
     D  peUserAgent                  64A   const options(*nopass:*omit)
     D  peContentType                64A   const options(*nopass:*omit)
     D  peSOAPAction                 64A   const options(*nopass:*omit)
      /else
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSOAPAction              16384A   varying const
     D                                     options(*nopass:*omit)
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_persist_req(): Perform (any) Persistent HTTP Request
      *
      *       peMethod = (input) Operation to perform. Should be one of:
      *                          'GET', 'DELETE', 'PUT', 'POST', 'HEAD'
      *         peComm = (input) pointer to persistent HTTP comm session
      *          peURL = (input) URL of resource to perform operation on
      * --------
      *        peUplFd = (input) Opaque integer to pass to peUplProc
      *      peUplProc = (input) Pointer to call-back procedure for
      *                          sending upload data to server during
      *                          PUT or POST requests. If this is null,
      *                          peUplData will be used, instead.
      *         NOTE: HTTPAPI considers data sent via the
      *               peUplProc to be "binary". If you want
      *               it translated, please do so in your program.
      * -- or --
      *      peUplData = (input) Pointer to data to upload in a PUT/POST
      *                          request. If this is null, peUplProc will
      *                          be used, instead.
      *         NOTE: HTTPAPI will translate the data in peUplData
      *               according to the values set in the pePostRem/pePostLoc
      *               parameters to http_setCCSIDs.
      *   peUplDataLen = (input) Total length, in bytes, of peUplData
      * --------
      *       peSaveFD = (input) Opaque integer passed to peSaveProc
      *     peSaveProc = (input) Pointer to call-back procedure that is
      *                          called when data is received from HTTP
      *                          server.
      *      peTimeout = (input/optional) time-out when no data is received
      *                          for this many seconds.
      *  peContentType = (input/optional) content type to supply (mainly
      *                          useful when talking to CGI scripts)
      *   peSOAPAction = (input/optional) string to send in the SOAPAction:
      *                          HTTP header when making a SOAP request.
      *      peModTime = (input/optional) only download file if it has
      *                          changed since (this timestamp).
      *
      *  Returns  1 if successful,
      *           0 if timed out
      *          -1 if an internal error occurs
      *          or an HTTP response code if an error comes from the server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist_req...
     D                 PR            10I 0
     D  peMethod                     10a   varying const
     D  peComm                         *   value
     D  peURL                     32767A   varying const options(*varsize)
     D  peUplFD                      10I 0 value
     D  peUplProc                      *   value procptr
     D  peUplData                      *   value
     D  peUplDataLen                 10I 0 value
     D  peSaveFD                     10I 0 value
     D  peSaveProc                     *   value procptr
     D  peTimeout                    10I 0 value options(*nopass)
     D  peUserAgent               16384A   varying const
     D                                     options(*nopass:*omit)
     D  peContentType             16384A   varying const
     D                                     options(*nopass:*omit)
     D  peSoapAction              32767A   varying const
     D                                     options(*nopass:*omit)
     D  peModTime                      Z   const options(*nopass:*omit)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_persist(): Perform (any) Persistent HTTP Request
      *
      *    Method = (input) HTTP method to use (GET, POST, PUT, etc)
      *      comm = (input) communication handle (from http_persist_open)
      *       URL = (input) URL to make request to
      *    Writer = (input) Writer that will save results
      *    Reader = (input) Reader that will retrieve data to send
      *
      *  Returns  1 if successful,
      *           0 if timed out
      *          -1 if an internal error occurs
      *          or an HTTP response code if an error comes from the server
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist    PR            10I 0
     D   Method                      10a   varying const
     D   comm                          *   value
     D   URL                      32767A   varying const options(*varsize)
     D   Writer                        *   const
     D   Reader                        *   const options(*nopass:*omit)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_persist_close(): End a persistent HTTP session
      *
      *     peComm = (input) pointer to persistent HTTP comm session
      *
      *  returns 0 if successful, -1 otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_persist_close...
     D                 PR            10I 0
     D  peComm                         *   value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_debug():  Turn debug/trace file *ON or *OFF
      *
      * NOTE: This creates a file (by default, /tmp/httpapi_debug.txt)
      *       that will contain many diagnostics of what transpired
      *       during an HTTP session. This is mainly used for debugging.
      *
      *      peStatus = (input) status (either *ON or *OFF)
      *
      *    peFilename = (input/optional) filename that debug info will be
      *                    written to. If not defined, the value from
      *                    CONFIG_H is used.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_debug      PR
     D   peStatus                     1N   const
     D   peFilename                 500A   varying const options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_SetCCSIDs():  Set the CCSIDs used for ASCII/EBCDIC
      *                    translation
      *
      *     pePostRem = (input) Remote CCSID of POST data
      *     pePostLoc = (input) Local CCSID of POST data
      *     peProtRem = (input) Remote CCSID of Protocol data
      *     peProtLoc = (input) Local CCSID of Protocol data
      *
      *  NOTE: if pePostRem = pePostLoc, it is assumed that the
      *        data is binary, and will not be translated.
      *
      * Returns 0 if successful, -1 otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_SetCCSIDs  PR            10I 0
     D   pePostRem                   10I 0 value
     D   pePostLoc                   10I 0 value
     D   peProtRem                   10I 0 value options(*nopass)
     D   peProtLoc                   10I 0 value options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_SetFileCCSID(): Set the CCSID that downloaded stream
      *                      files get tagged with
      *
      *     peCCSID  = (input) New CCSID to assign
      *
      * NOTE: HTTPAPI does not do *any* translation of downloaded
      *       data. It only sets this number as part of the file's
      *       attributes.  You can change it with the CHGATR CL
      *       command.
      *
      * NOTE: The IFS did not support CCSIDs in V4R5 and earlier.
      *       On those releases, this API will be used to set the
      *       codepage rather than the CCSID.
      *
      * Returns 0 if successful, -1 otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_SetfileCCSID...
     D                 PR
     D   peCCSID                     10I 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_xlate():  Translate data from ASCII <--> EBCDIC
      *
      *  Translation is done using the HTTP protocol translation
      *  table. Consider using http_xlatedyn instead!
      *
      *       peSize = (input) Size of data to translate
      *       peData = (input) Data
      *  peDirection = (input) can be set to the TO_ASCII or
      *                         TO_EBCDIC constant.
      *
      * Returns 0 if successful, -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_xlate      PR            10I 0
     D   peSize                      10I 0 value
     D   peData                   32766A   options(*varsize)
     D   peDirection                  1A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_xlatep(): Translate data from ASCII <--> EBCDIC
      *                (using a pointer instead of a variable)
      *
      *  Translation is done using the HTTP protocol translation
      *  table. Consider using http_xlatedyn instead!
      *
      *       peSize = (input) Size of data to translate
      *       peData = (input) Data
      *  peDirection = (input) can be set to the TO_ASCII or
      *                         TO_EBCDIC constant.
      *
      * Returns 0 if successful, -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_xlatep     PR            10I 0
     D   peSize                      10I 0 value
     D   peData                        *   value
     D   peDirection                  1A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_xlatedyn: Translate data from ASCII <--> EBCDIC
      *                using a dynamically sized output buffer
      *
      * Translation is done using the "post data" translation table
      * if http_setCCSIDs() is called with pePostRem=pePostLoc, then
      * data will be copied to a newly allocated buffer, but will
      * not be translated
      *
      *      peSize = (input) size of data to translate
      *      peData = (input) pointer to data to translate
      * peDirection = (input) TO_ASCII or TO_EBCDIC
      *    peOutput = (output) address of newly allocated memory
      *
      * returns the length of the translated data or -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_xlatedyn   PR            10I 0
     D   peSize                      10I 0 value
     D   peData                        *   value
     D   peDirection                  1A   const
     D   peOutput                      *


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_set_100_timeout(): Set value for 100-continue timeouts.
      *
      * HTTP's POST/PUT operations have a feature to let you detect
      * where your request URI is valid prior to uploading a document
      * body (such as POST data or a file upload).
      *
      * HTTPAPI can send "Expect: 100-continue" and the server should
      * reply with status 100 to indicate that the upload should proceed
      * or else provide an error message if the upload should not proceed.
      *
      * Despite being a part of the HTTP/1.1 protocol standard, many
      * servers do not implement this properly.
      *
      * Therefore:
      *    a) You may set the timeout to 0. HTTPAPI will not attempt
      *         to use the 100-continue feature.
      *    b) You may set the timeout to a low value, so that HTTPAPI
      *         will use the feature if possible, but will time
      *         quickly if the feature isn't implemented
      *    c) You may set the timeout to a higher value if you want
      *         to ensure that HTTPAPI always waits for it before
      *         sending an upload.
      *
      * The timeout value is expressed in seconds, and may range
      * from 0.001 (1 millisecond) to 9999999.999 (approx 116 days)
      * or 0 = don't wait at all.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_set_100_timeout...
     D                 PR
     D   peTimeout                   10P 3 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_xml_SetCCSIDs():  Set the CCSIDs used for ASCII/EBCDIC
      *                    translation for XML documents
      *
      *     peRemote = (input) remote CCSID
      *     peLocal  = (input) local CCSID (can be 0 if you want
      *                 to use the CCSID of the current job)
      *
      * Returns 0 if successful, -1 otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_xml_SetCCSIDs...
     D                 PR            10I 0
     D   peRemote                    10I 0 value
     D   peLocal                     10I 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_parse_xml_stmf(): Parse XML data directly from a stream file
      *                         (instead of downloading it from a server)
      *
      *      peFile = (input) Stream file (in IFS) to read data from
      *     peCCSID = (input) CCSID of stream file,
      *                    or HTTP_XML_CALC to attempt to calculate it
      *                       from the XML encoding
      *                    or HTTP_STMF_CALC to use the stream file's
      *                       CCSID attribute.
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *
      *  Returns  -1 upon failure, 0 if successful
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parse_xml_stmf...
     D                 PR            10I 0
     D  peFile                    32767A   varying const options(*varsize)
     D  peCCSID                      10I 0 value
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value

     D HTTP_XML_CALC   C                   -1
     D HTTP_STMF_CALC  C                   -2


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_header():  retrieve the value of an HTTP header
      *
      *      name = (input) name of header to look for
      *       pos = (input/optional) position of header if there's
      *                 more than one with the same name
      *
      * returns the value of the HTTP header, or '' if not found
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_header     PR         32500A   varying
     D   name                       256A   varying const
     D   pos                         10I 0 value options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_use_cookies(): Turns on/off HTTPAPI's cookie parsing and
      *                     caching routines.
      *
      *    peSetting = (input) *ON = HTTPAPI will read and send cookies
      *                       *OFF = HTTPAPI will ignore cookies
      *                              (has no affect on cookies supplied
      *                               via an exit procedure)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_use_cookies...
     D                 PR
     D   peSetting                    1N   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_cookie_file():  Set the name of the file that HTTPAPI
      *          will use to store cookies.
      *
      *    peFilename = (input) Filename (IFS path) to store cookie
      *                  data into.
      *     peSession = (input) include session cookies (temp cookies)
      *                  in cookie file?  Default = *OFF
      *
      *  If the filename is set to '', or if you do not call this API,
      *  cookies will only be saved until the activation group is
      *  reclaimed.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_cookie_file...
     D                 PR
     D   peFilename                 256A   varying const
     D   peSession                    1n   const options(*nopass:*omit)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_comp(): Send a completion message
      *
      *      peMessage = message to send.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_comp       PR
     D   peMessage                  256A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_diag(): Send a diagnostic message
      *
      *      peMessage = message to send.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_diag       PR
     D   peMessage                  256A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_crash(): Send back an *ESCAPE message containing last
      *               error found in HTTPAPI.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_crash      PR


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_tempfile():  Generate a unique temporary IFS file name
      *
      * returns the file name
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_tempfile   PR            40A   varying


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_xmlns():  Enable XML Namespace processing
      *
      *     peEnable = (input) *ON to enable parsing, *OFF to disable.
      *                        (it is disabled by default)
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
     D http_xmlns      PR
     D   peEnable                     1N   const


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_XmlReturnPtr(): XML End Element Handler should return a
      *                      pointer to the full element value instead of
      *                      returning a VARYING character string.
      *                      (VARYING is limited to 64k)
      *
      *     peEnable = (input) *ON to return a pointer, *OFF to return
      *                        a VARYING string (*OFF = default)
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
     D http_XmlReturnPtr...
     D                 PR
     D   peEnable                     1N   const


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_XmlStripCRLF(): Enable stripping of CRLF characters
      *
      *     peEnable = (input) *ON to strip, *OFF to leave them in.
      *                        (they are stripped by default)
      *
      * Note: To simplify your XML string manipulations, HTTPAPI
      *       strips CRLF characters from the response.  If you would
      *       prefer that they are left in the response, call this
      *       routine with a parameter of *OFF.
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
     D http_XmlStripCRLF...
     D                 PR
     D   peEnable                     1N   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_parser_switch_cb(): delegates element processing to another
      *     set of start and end element callback procedures for the
      *     current element and its children.
      *
      *    peUsrDta = (input) user-defined data that will be passed to
      *                       the call-back routine. usuallay only that
      *                       portion of the curent user data is forwarded
      *                       to the new callback procedures that they are
      *                       responsible for.
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *
      *  Returns  -1 upon failure, 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_switch_cb...
     D                 PR            10I 0
     D  peUsrDta                       *   value
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr options(*nopass)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_parser_get_start_cb(): returns the procedure pointer of
      *     the currently active start callback procedure.
      *
      *  Returns procedure pointer of start callback procedure.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_get_start_cb...
     D                 PR              *   procptr

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_parser_get_end_cb(): returns the procedure pointer of
      *     the currently active end callback procedure.
      *
      *  Returns procedure pointer of end callback procedure.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_get_end_cb...
     D                 PR              *   procptr

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_parser_get_userdata(): returns the procedure pointer of
      *     the currently active user data.
      *
      *  Returns procedure pointer of user data.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_get_userdata...
     D                 PR              *


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_parse_xml_string():  Parse XML from an input string.
      *                         (instead of downloading it from a server)
      *
      *    peString = (input) Pointer to string
      *       peLen = (input) Length of string to parse
      *     peCCSID = (input) CCSID of string to be parsed
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *
      *  Returns  -1 upon failure, 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parse_xml_string...
     D                 PR            10i 0
     D  peString                       *   value
     D  peLen                        10I 0 value
     D  peCCSID                      10I 0 value
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_nextXmlAttr():  Retrieve next XML attribute from attrs list
      *
      *      attrs = (input) attribute list to extract from
      *        num = (i/o)   position in attribute list.  On first
      *                      call, set this to 1.  HTTPAPI will
      *                      increment this as it moves through the list
      *       name = (output) XML attribute name (from list)
      *        val = (output) XML attribute value (from list)
      *
      * Returns *ON normally, *OFF if there's no more attributes to read
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_nextXmlAttr...
     D                 PR             1N
     D   attrs                         *   dim(32767)
     D                                     const options(*varsize)
     D   num                         10i 0
     D   name                      1024a   varying
     D   val                      65535a   varying


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_EscapeXml(): Escape any special characters used by XML
      *
      *     peString = (input) string to escape
      *
      * Returns escaped string.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_EscapeXml  PR          4096a   varying
     D  peString                   4096a   varying const


      /if defined(HTTP_WSDL2RPG_STUFF)
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_getContentType():  returns the content type of the
      *                         HTTP response stream
      *
      * returns the content type of the HTTP stream, or '' if not found
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_getContentType...
     D                 PR         32500A   varying


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_getContentSubType():  returns the content sub type of the
      *                            HTTP response stream
      *
      * returns the content sub type of the HTTP stream, or '' if not found
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_getContentSubType...
     D                 PR         32500A   varying


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_getContentAttr(): returns the value of the specified
      *                        attribute of the content type header
      *                        of the HTTP response stream
      *
      *      attr = (input) name of content-type header attribute to look for
      *
      * returns the value of the content-type header attribute, or '' if not found
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_getContentTypeAttr...
     D                 PR         32500A   varying
     D   attr                       256A   varying const
      /endif


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_dwrite(): Write raw (binary) data to the HTTPAPI debug
      *                log.
      *
      *    peData = pointer to raw data to write
      *    peLen  = length of the data to write
      *
      * NOTE: The debug log is opened the first time http_dwrite()
      *       or http_dmsg() is called, and closed at the end of a
      *       an HTTP transaction (such as GET or POST) If you attempt
      *       to write after a transaction, the file will be re-opened
      *       and not closed until the next transaction, or until
      *       http_dclose() is called.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_dwrite     PR
     D   peData                        *   value
     D   peLen                       10I 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_dmsg(): Write one line of text to the HTTPAPI debug log
      *
      *    peMsgTxt = one message (one line of text) to write to
      *                the debug log.  CRLF will be added for you
      *                and the data will be undergo EBCDIC->ASCII
      *                translation as it's written.
      *
      * NOTE: The debug log is opened the first time http_dwrite()
      *       or http_dmsg() is called, and closed at the end of a
      *       an HTTP transaction (such as GET or POST) If you attempt
      *       to write after a transaction, the file will be re-opened
      *       and not closed until the next transaction, or until
      *       http_dclose() is called.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_dmsg       PR
     D   peMsgTxt                   256A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_dclose():  Close the HTTPAPI debug log.
      *
      * NOTE: Calling http_dmsg or http_dwrite will automatically
      *       reopen the log. The log is automatically closed at
      *       the end of an HTTP transaction (such as GET or POST)
      *       If you want to close it at another time, call this
      *       routine.
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_dclose     PR


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_XmlReturnUCS(): The XML End Handler should get it's data
      *                      in UCS-2 Unicode (RPG data type C) instead
      *                      of EBCDIC (RPG data type A)
      *
      *     peEnable = (input) *ON to return data in Unicode
      *                       *OFF to return data in EBCDIC (default)
      *
      * NOTE: This can be used in conjunction with http_XmlReturnPtr.
      *       When XmlReturnPtr is off, the data is returned as a
      *       UCS-2 VARYING parameter.  When XmlReturnPtr=on, the data
      *       is returned as a pointer to a DS containing UCS-2
      *       data (as opposed to alphanumeric)
      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
     D http_XmlReturnUCS...
     D                 PR
     D   peEnable                     1N   const


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_parser_init():   Initializes the XML parser.
      *                       Afterwards http_parser_parseChunk() can
      *                       can be used to parse a given XML stream.
      *
      *     peCCSID = (input) CCSID of string to be parsed
      * peStartProc = (input) call-back procedure to call at the start
      *                       of each XML element received.
      *   peEndProc = (input) call-back procedure to call at the end
      *                       of each XML element received.
      *    peUsrDta = (input) user-defined data that will be passed
      *                          to the call-back routine
      *
      * Returns the length of the parsed data or -1 upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_init...
     D                 PR
     D  peCCSID                      10I 0 const options(*omit)
     D  peStartProc                    *   value procptr
     D  peEndProc                      *   value procptr
     D  peUsrDta                       *   value


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_parser_parseChunk():  Parses a given chunk of XML data.
      *                            Can be invoked multiple times in
      *                            between http_parser_init() and
      *                            http_parser_free.
      *
      *        peFD = (input) Open file descriptor. Not used here but
      *                       required for compatibility reasons.
      *      peData = (input) Pointer of the XML data.
      *    peLength = (input) Length of the XML data.
      *
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_parseChunk...
     D                 PR            10I 0
     D   peFD                        10I 0 value
     D   peData                        *   value  options(*string)
     D   peLength                    10I 0 value


      *++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ +
      * http_parser_free():  Frees a previously allocated parser.
      *
      *  peUpdError = (input) Update error information. Default: *ON.
      *
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_parser_free...
     D                 PR            10I 0
     D   peUpdError                    N   const  options(*nopass: *omit)


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_setDebugLevel(): Set the debug log level
      *
      *    peDbgLvl = (input) new level to use
      *                1 = Normal
      *                2 = More detailed comm timeout/performance info
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_setDebugLevel...
     D                 PR
     D    peDbgLvl                   10i 0 value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_ParseURL(): Parse URL into it's component parts
      *
      *  NOTE: This is primarily used internally to HTTPAPI, you probably
      *        won't need to use it.
      *
      *  Breaks a uniform resource locator (URL) into it's component
      *  pieces for use with the http: or https: protocols.  (would also
      *  work for FTP with minor tweaks)
      *
      *       peURL = (input) URL that needs to be parsed.
      *   peService = (output) service name from URL (i.e. http or https)
      *  peUserName = (output) user name given, or *blanks
      *  pePassword = (output) password given, or *blanks
      *      peHost = (output) hostname given in URL
      *      pePort = (output) port number if given, or 80 if not
      *      pePath = (output) remaining path/query string for server
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_ParseURL   PR            10I 0
     D  peURL                       256A   const
     D  peService                    32A
     D  peUserName                   32A
     D  pePassword                   32A
     D  peHost                      256A
     D  pePort                       10I 0
     D  pePath                      256A


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_build_sockaddr(): Build a socket address structure for a host
      *
      *  NOTE: This is primarily used internally to HTTPAPI, you probably
      *        won't need to use it.
      *
      *        peHost = hostname to build sockaddr_in for
      *     peService = service name (or port) to build sockaddr_in for
      *   peForcePort = numeric port to force entry to, overrides peService
      *    peSockAddr = pointer to a location to place a sockaddr_in into.
      *             (if *NULL, memory will be allocated, otherwise it will
      *                be re-alloc'ed)
      *
      *   returns -1 upon failure, 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_build_sockaddr...
     D                 PR            10I 0
     D   peHost                     256A   const
     D   peService                   32A   const
     D   peForcePort                 10I 0 value
     D   peSockAddr                    *

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_close(): close HTTP connection
      *
      *  NOTE: This is primarily used internally to HTTPAPI, you probably
      *        won't need to use it.
      *
      *    peSock = socket to close
      *    peComm = comm driver opened with http_select_commdriver()
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_close      PR            10I 0
     D  peSock                       10I 0 value
     D  peComm                         *   value


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      *  http_long_ParseURL(): Parse URL into it's component parts
      *
      *  NOTE: This is primarily used internally to HTTPAPI, you probably
      *        won't need to use it.
      *
      *  Breaks a uniform resource locator (URL) into it's component
      *  pieces for use with the http: or https: protocols.  (would also
      *  work for FTP with minor tweaks)
      *
      *  peURL = URL that needs to be parsed.
      *  peService = service name from URL (i.e. http or https)
      *  peUserName = user name given, or *blanks
      *  pePassword = password given, or *blanks
      *  peHost = hostname given in URL. (could be domain name or IP)
      *  pePort = port number to connect to, if specified, otherwise 0.
      *  pePath = remaining path/request for server.
      *
      *  returns -1 upon failure, or 0 upon success
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     d http_long_ParseURL...
     D                 PR            10I 0
     D  peURL                     32767A   varying const options(*varsize)
     D  peService                    32A
     D  peUserName                   32A
     D  pePassword                   32A
     D  peHost                      256A
     D  pePort                       10I 0
     D  pePath                    32767A   varying

      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * http_select_commdriver():  Select & initialize communications
      *    driver.
      *
      *  NOTE: This is primarily used internally to HTTPAPI, you probably
      *        won't need to use it.
      *
      *      peCommType = (input) communications type (http/https)
      *
      * Returns pointer to comm driver, or *NULL upon failure
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D http_select_commdriver...
     D                 PR              *
     D   peCommType                  32A   const


      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      * HTTP_SetTables():  Set the translation tables used for
      *                    ASCII/EBCDIC translation
      *
      *  NOTE: This is obsolete. Please use http_setCCSIDs instead.
      *
      *     peASCII  = (input) Table for converting to ASCII
      *     peEBCDIC = (input) Table for converting to EBCDIC
      *
      * Returns 0 if successful, -1 otherwise
      *+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     D HTTP_SetTables  PR            10I 0
     D   peASCII                     10A   const
     D   peEBCDIC                    10A   const


      *********************************************************************
      **  Error codes that HTTP API can return
      *********************************************************************
      ** Invalid URL format
     D HTTP_BADURL     C                   CONST(1)
      ** Host not found (not a valid IP address, or DNS lookup failed)
     D HTTP_HOSTNF     C                   CONST(2)
      ** Unable to create a new socket
     D HTTP_SOCERR     C                   CONST(4)
      ** Error when connecting to server
     D HTTP_BADCNN     C                   CONST(6)
      ** Timeout when connecting to server
     D HTTP_CNNTIMO    C                   CONST(7)
      ** HTTP response code logged (not an error, per se)
     D HTTP_RESP       C                   CONST(13)
      ** Error calling user-specified procedure in the
      **   recvdoc() procedure.  (user proc must return full count)
     D HTTP_RDWERR     C                   CONST(16)
      ** Unsupported transfer-encoding value
     D HTTP_XFRENC     C                   CONST(20)
      ** Error opening file to save data into.
     D HTTP_FDOPEN     C                   CONST(22)
      ** Problem with the Application ID for the DCM
     D HTTP_GSKAPPID   C                   CONST(23)
      ** Error setting auth type
     D HTTP_GSKATYP    C                   CONST(24)
      ** Error initializing GSKit environment
     D HTTP_GSKENVI    C                   CONST(25)
      ** Error opening GSKit environment
     D HTTP_GSKENVO    C                   CONST(26)
      ** Error setting session type (client | server | server_auth)
     D HTTP_GSKSTYP    C                   CONST(27)
      ** Error registering application w/DCM
     D HTTP_REGERR     C                   CONST(28)
      ** Error open secure socket
     D HTTP_SSOPEN     C                   CONST(29)
      ** Error setting SSL numeric file descriptor
     D HTTP_SSSNFD     C                   CONST(30)
      ** Error setting SSL numeric timeout value
     D HTTP_SSSNTO     C                   CONST(31)
      ** SSL handshake timed out
     D HTTP_SSTIMO     C                   CONST(32)
      ** This app is not registered with digital cert mgr
     D HTTP_NOTREG     C                   CONST(35)
      ** This URI needs authorization (user/pass)
     D HTTP_NDAUTH     C                   CONST(36)
      ** Invalid HTTP authentication type
     D HTTP_ATHTYP     C                   CONST(37)
      ** Error in value of an HTTP authentication string
     D HTTP_ATHVAL     C                   CONST(38)
      ** Server didn't ask for authorizatin
     D HTTP_NOAUTH     C                   CONST(39)
      ** blockread() timed out waiting for more data
     D HTTP_BRTIME     C                   CONST(43)
      ** blockread() error during recv() call
     D HTTP_BRRECV     C                   CONST(44)
      ** blockread() error during select() call
     D HTTP_BRSELE     C                   CONST(45)
      ** recvchunk() did not get the trailing CRLF chars
     D HTTP_RDCRLF     C                   CONST(46)
      ** Invalid exit point registered with HTTP_Xproc()
     D HTTP_BADPNT     C                   CONST(47)
      ** Error retrieving SSL protocol
     D HTTP_SSPROT     C                   CONST(48)
      ** Unknown SSL protocol
     D HTTP_SSPUNK     C                   CONST(49)
      ** Error setting SSL protocol
     D HTTP_SSPSET     C                   CONST(50)
      ** Out of memory
     D HTTP_NOMEM      C                   CONST(51)
      ** Must give data in order to encode it
     D HTTP_NODATA     C                   CONST(52)
      ** Pointer is invalid or already freed
     D HTTP_INVPTR     C                   CONST(53)
      ** Not enough space to add encoded variable
     D HTTP_NOSPAC     C                   CONST(54)
      ** Error calling send() API in BlockWrite()
     D HTTP_BWSEND     C                   CONST(55)
      ** Error calling select() API in BlockWrite()
     D HTTP_BWSELE     C                   CONST(56)
      ** Timeout waiting to send in BlockWrite()
     D HTTP_BWTIME     C                   CONST(57)
      ** Lineread() had problem with recv() API
     D HTTP_LRRECV     C                   CONST(58)
      ** Lineread() had problem with select() API
     D HTTP_LRSELE     C                   CONST(59)
      ** Lineread() had timeout
     D HTTP_LRTIME     C                   CONST(60)
      ** Procedure is no longer supported
     D HTTP_NOTSUPP    C                   CONST(61)
      ** No communication driver defined
     D HTTP_NOCDRIV    C                   CONST(62)
      ** Timeout sending data in blockwrite
     D HTTP_BWTIMO     C                   CONST(63)
      ** Timeout sending data in blockwrite
     D HTTP_SWCERR     C                   CONST(64)
      ** Timeout sending data in blockwrite
     D HTTP_FDSTAT     C                   CONST(65)
      ** Error parsing XML data
     D HTTP_XMLERR     C                   CONST(66)
      ** Error opening IFS file
     D HTTP_IFOPEN     C                   CONST(67)
      ** Error with SSL keyring
     D HTTP_GSKKEYF    C                   CONST(68)
      ** Must Use Table / Must not Use Table
     D HTTP_MUTABLE    C                   CONST(69)
      ** Cookie file cant be written
     D HTTP_CKDUMP     C                   CONST(70)
      ** Cookie file cant be read
     D HTTP_CKOPEN     C                   CONST(71)
      ** Can't get stats on cookie file
     D HTTP_CKSTAT     C                   CONST(72)
      ** Error converting CCSIDs
     D HTTP_CONVERR    C                   CONST(73)
      ** Error setting stream file CCSID
     D HTTP_SETATTR    C                   CONST(74)
      ** This Proxy server needs authorization (user/pass)
     D HTTP_PXNDAUTH   C                   CONST(75)
      ** XML callback switched illegally
     D HTTP_ILLSWC     C                   CONST(76)
      ** Error getting certificate info
     D HTTP_SSLGCI     C                   CONST(77)
      ** Error from certificate validation callback
     D HTTP_SSLVAL     C                   CONST(78)
      ** Error setting TLS versions
     D HTTP_TLSSET     C                   CONST(79)
      ** Error with a Reader/Writer
     D HTTP_BAD_RDWR   C                   CONST(80)


      *********************************************************************
      *  HTTP WWW-Authentication types
      *********************************************************************
     D HTTP_AUTH_NONE...
     D                 C                   '0'
     D HTTP_AUTH_BASIC...
     D                 C                   '1'
     D HTTP_AUTH_MD5_DIGEST...
     D                 C                   '2'
     D HTTP_AUTH_NTLM...
     D                 C                   '3'


      *********************************************************************
      *  HTTPAPI Exit points
      *********************************************************************
      ** Debug exit point:  This is called when ASCII stream data is to be
      **                    to a log file.   Here's the prototype for a
      **                    debug exit procedure:
      **
      **  D debug_proto     PR
      **  D   DataToLog                     *   value
      **  D   Length                      10I 0 value
      **
     D HTTP_POINT_DEBUG...
     D                 C                   1

      ** Upload status exit point:  This is called periodically during an
      **                            upload (POST) to an HTTP(S) server.
      **                            Allows you to display progress to the
      **                            user.
      **
      **  D upload_proto    PR
      **  D   BytesSent                   10U 0 value
      **  D   BytesTotal                  10U 0 value
      **
     D HTTP_POINT_UPLOAD_STATUS...
     D                 C                   2

      ** Download status exit point:  This is called periodically during a
      **                              download (POST or GET) from an HTTP(S)
      **                              server.  Allows you to display the
      **                              progress to the user.
      **
      **  D download_proto  PR
      **  D   BytesRecv                   10U 0 value
      **  D   BytesTotal                  10U 0 value
      **
     D HTTP_POINT_DOWNLOAD_STATUS...
     D                 C                   3

      ** Additional Header fields exit point:
      **    Allows you to supply additional header data to be added
      **    to the HTTP request chain.  Data should be in EBCDIC with
      **    x'0d25' after each header record.
      **
      **  D addl_hdrs_prot  PR
      **  D   HeaderData                1024A   varying
      **
     D HTTP_POINT_ADDL_HEADER...
     D                 C                   4

      ** Header parse exit point:
      **    Allows you to examine the HTTP response chain received
      **    from the HTTP server.
      **
      **  D parse_hdr_prot  PR
      **  D   HeaderData                2048A   const
      **
     D HTTP_POINT_PARSE_HEADER...
     D                 C                   5

      ** Header parse exit point:
      **    Allows you to examine the HTTP response chain received
      **    from the HTTP server. (allows longer headers)
      **
      **  D parse_hdr_long  PR
      **  D   HeaderData               32767A   const varying
      **
     D HTTP_POINT_PARSE_HDR_LONG...
     D                 C                   6

      ** SSL Certificate validation:
      **    This will be called repeatedly for each field in each
      **    certificate when parsed by HTTPAPI.
      **
      **  D cert_valid      PR            10i 0
      **  D   usrdta                        *   value
      **  D   id                                like(CERT_DATA_ID) value
      **  D   data                     32767a   varying const
      **  D   errmsg                      80a
      **
      **     id = certificate data id (see CERT_DATA_ID_T in GSKSSL_H)
      **   data = certificate element data.  (For binary elements, this
      **          is binary data. For others, it'll be EBCDIC data.)
      ** errmsg = the callback can use this to return a reason why a
      **          certificate wasn't valid.  (retrievable w/HTTP_error)
      **
      **  Return 0 if okay, -1 if you want to reject it.
      **
     D HTTP_POINT_CERT_VAL...
     D                 C                   7

      ** SSL Certificate validation (GSkit)
      **    This sets the GSK_CERT_
      **    within GSKit.  The GSKit (not HTTPAPI) will call back
      **    your procedure to validate a certificate.
      **
      **    See the gsk_attribute_set_callback() API documentation
      **    in the IBM Information Center for details.
      **
      **    Note: The UserData parameter to http_xproc() will be
      **          passed as the 3rd parameter to the
      **          gsk_attribute_set_callback() API -- the peProc
      **          parameter to http_xproc() is ignored for this
      **          exit point.
      **
     D HTTP_POINT_GSKIT_CERT_VAL...
     D                 C                   8


      *********************************************************************
      * Directions for HTTP_xlate() and HTTP_xlatep()
      *********************************************************************
     D TO_ASCII        C                   '1'
     D TO_EBCDIC       C                   '2'
     D TO_NETWORK      C                   '1'
     D TO_SYSTEM       C                   '2' 