**free
ctl-opt option(*nodebugio:*srcstmt:*nounref) decedit('0,') bnddir('HTTPAPI':'YAJL');

dcl-f httpgetjsd workstn indds(indicators);

/include httpapi_h
/include yajl_h

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

dcl-s jsonString varchar(100000) ccsid(1208);

dcl-s response   sqltype(clob:10000) ccsid(1208);
// Compiler will generate this:
//   dcl-ds response
//     response_len  uns(10);
//     response_data char(10000) ccsid(1208);
//   end-ds;

dcl-s ifsFile1   sqltype(clob_file)ccsid(1208);
// The compiler will generate this:
//  dcl-ds ifsFile1 inz;
//     ifsFile1_nl   uns(10);
//     ifsFile1_dl   uns(10);
//     ifsFile1_fo   uns(10);
//     ifsFile1_name char(255) ccsid(1208)
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

dcl-s url       varchar(1000);
dcl-s docNode   like(yajl_val);
dcl-s node      like(yajl_val);
dcl-s val       like(yajl_val);
dcl-s descrip   like(yajl_val);
dcl-s key       varchar(50);
dcl-s errMsg    varchar(500);
dcl-s i         int(10);
dcl-s j         int(10);

exec sql set option commit = *none, closqlcsr = *endmod;

pgmname = 'HTTPAPIJS';

url='http://api.weatherstack.com/current?access_key=45adb533dd9e6ea52ccb81accd8bb8bc&query=madrid';

// http_string returns a varchar(100000)
jsonString = http_string('GET':url);

response_data = jsonString;
response_len  = %len(jsonString);

ifsFile1_name = '/home/asalcedo/common/belgium/weather_http_string.json';
ifsFile1_nl   = %len(%trim(ifsFile1_name));
ifsFile1_fo   = SQFOVR;

// Saves the contents of the clob to the file
exec sql set :ifsFile1 = :response;

docNode = yajl_string_load_tree(jsonString:errMsg);
if errMsg <> '';
  snd-msg 'Error loading JSON string.' %target(*self:2);
  snd-msg errMsg %target(*self:2);
endif;

node = yajl_object_find(docNode:'location');
i=0;
dow yajl_object_loop(node:i:key:val);
  select key;
    when-is 'name';
      location.name = yajl_get_string(val);
    when-is 'country';
      location.country = yajl_get_string(val);
    when-is 'region';
      location.region = yajl_get_string(val);
    when-is 'lat';
      location.lat = yajl_get_string(val);
    when-is 'lon';
      location.lon = yajl_get_string(val);
    when-is 'timezone_id';
      location.timezone_id = yajl_get_string(val);
    when-is 'localtime';
      location.localtime = yajl_get_string(val);
  endsl;
enddo;

node = yajl_object_find(docNode:'current');
i = 0;
dow yajl_object_loop(node:i:key:val);
  select key;
    when-is 'temperature';
      current.temperature = yajl_get_number(val);
    when-is 'weather_descriptions';
      descrip = yajl_object_find(node:'weather_descriptions');
      j = 0;
      dow yajl_array_loop(descrip:j:val);
        current.weather_descriptions(j) = yajl_get_string(val);
      enddo;
      current.num_weather_descriptions = (j-1);
    when-is 'wind_speed';
      current.wind_speed = yajl_get_number(val);
    when-is 'wind_degree';
      current.wind_degree = yajl_get_number(val);
    when-is 'wind_dir';
      current.wind_dir = yajl_get_string(val);
    when-is 'pressure';
      current.pressure = yajl_get_number(val);
    when-is 'precip';
      current.precip = yajl_get_number(val);
    when-is 'humidity';
      current.humidity = yajl_get_number(val);
    when-is 'cloudcover';
      current.cloudcover = yajl_get_number(val);
    when-is 'feelslike';
      current.feelslike = yajl_get_number(val);
    when-is 'uv_index';
      current.uv_index = yajl_get_number(val);
    when-is 'visibility';
      current.visibility = yajl_get_number(val);
  endsl;
enddo;

yajl_tree_free(docNode);

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