**free
ctl-opt option(*nodebugio:*srcstmt:*nounref) decedit('0,');

dcl-f httpgetjsd workstn indds(indicators);

dcl-ds indicators;
  exit     ind pos(03);
  descrip2 ind pos(40);
  descrip3 ind pos(41);
end-ds;

dcl-ds locRec  likerec(loc_fmt:*output);
dcl-ds currRec likerec(curr_fmt:*all);

dcl-ds location qualified;
  name        varchar(50);
  country     varchar(50);
  region      varchar(50);
  lat         varchar(50);
  lon         varchar(50);
  timezone_id varchar(50);
  localtime   varchar(50);
end-ds;

dcl-ds current qualified;
  temperature              zoned(3);
  num_weather_descriptions zoned(1);
  weather_descriptions     varchar(100) dim(3);
  wind_speed               zoned(3);
  wind_degree              zoned(3);
  wind_dir                 varchar(3);
  pressure                 zoned(4);
  precip                   zoned(3);
  humidity                 zoned(3);
  cloudcover               zoned(3);
  feelslike                zoned(3);
  uv_index                 zoned(3);
  visibility               zoned(3);
end-ds;

dcl-s response  sqltype(clob:10000) ccsid(1208);
// Compiler will generate this:
//   dcl-ds response
//     response_len  uns(10);
//     response_data char(10000) ccsid(1208);
//   end-ds;

dcl-s ifsFile1 sqltype(clob_file)ccsid(1208);
// The compiler will generate this:
//  dcl-ds ifsFile inz;
//     ifsFile1_nl   uns(10);
//     ifsFile1_dl   uns(10);
//     ifsFile1_fo   uns(10);
//     ifsFile1_name char(255);
//  end-ds;
//
// _name = Name of the file (full path)
// _nl   = Length of the name of the file
// _fo   = Operation to be done in the file (see constants below)
// _dl   = Not used
//
// The compiler adds this constants too:
//   SQFRD  = 2  = Read file.
//   SQFCRT = 4  = Create file if not exists otherwise will raise an error.
//   SQFOVR = 8  = Overwrite file if exists otherwise create a new one.
//   SQFAPP = 16 = Append to file if exists otherwise create a new one.

dcl-s url varchar(1000);

exec sql set option commit = *none, closqlcsr = *endmod;

pgmname = 'HTTPGETJS';

// Put your own api key. It's free just get yours from https://weatherstack.com
url='http://api.weatherstack.com/current?access_key=xxxxxxxxxxxxxxxxxxxxxxxxxx&query=madrid';

// http_get returns a CLOB up to 2GB CCSID 1208. In the example it is held in a 10KB CLOB
exec sql
  values (qsys2.http_get(:url))
    into :response;

ifsFile1_name = '/home/asalcedo/common/europe/weather_http_get.json';
ifsFile1_nl   = %len(%trim(ifsFile1_name));
ifsFile1_fo   = SQFOVR;

// Saves the contents of the clob to the file
exec sql set :ifsFile1 = :response;

data-into location %data(response_data: 'allowextra=yes path=json/location')
                   %parser('YAJLINTO':'{"document_name":"json" }');

data-into current %data(response_data: 'allowextra=yes path=json/current countprefix=num_')
                  %parser('YAJLINTO':'{"document_name":"json" }');

write header;
write fkeys;

eval-corr locRec = location;
locRec.timezone = location.timezone_id;

eval-corr currRec = current;
currRec.temp = current.temperature;
currRec.desc1 = current.weather_descriptions(1);
if current.num_weather_descriptions >= 2;
  descrip2 = *on;
  currRec.desc2 = current.weather_descriptions(2);
  if current.num_weather_descriptions = 3;
    descrip3 = *on;
    currRec.desc3 = current.weather_descriptions(3);
  endif;
endif;
currRec.winddegree = current.wind_degree;

dow not exit;
  write loc_fmt locRec;
  exfmt curr_fmt currRec;
enddo;

*inlr = *on; 
