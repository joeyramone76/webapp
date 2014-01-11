import time;
import datetime;

ts = time.time();
print ts;
st = datetime.datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S');
print st;

print datetime.datetime.utcnow();
print datetime.datetime.now();
print str(datetime.datetime.now());
print datetime.datetime.now().strftime("%A, %d. %B %Y %I:%M%p");
print datetime.datetime.now().isoformat();