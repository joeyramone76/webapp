django-admin.py startproject mysite
python manage.py runserver 0.0.0.0:8000
python manage.py syncdb
python manage.py sql polls
python manage.py validate
python manage.py sqlcustom polls
python manage.py sqlclear polls
python manage.py sqlindexes polls
python manage.py sqlall polls
python manage.py shell

from polls.models import Poll;
Poll.objects.all();

from django.utils import timezone
p = Poll(question="What's news?", pub_date=timezone.now())
p.save()

p.id
p.question
p.pub_date

p.question = "What's up?";
p.save();

Poll.objects.all();

from polls.models import Poll, Choice
Poll.objects.all();

Poll.objects.filter(id=1);
Poll.objects.filter(question__startswith='What');

from django.utils import timezone;
current_year = timezone.now().year;
Poll.objects.get(pub_date__year=current_year);

Poll.objects.get(id=2)

p = Poll.objects.get(pk=1)
p.was_published_recently()

p.choice_set.all();
p.choice_set.create(choice_text='Not much', votes=0);
p.choice_set.create(choice_text='The sky', votes=0);
c = p.choice_set.create(choice_text='Just hacking again', votes=0);

c.poll;
p.choice_set.all();
p.choice_set.count();

Choice.objects.filter(poll__pub_date__year=current_year)
c = p.choice_set.filter(choice_text__startswith='Just hacking');
c.delete();

import datetime;
from django.utils import timezone;
from polls.models import Poll;

future_poll = Poll(pub_date=timezone.now() + datetime.timedelta(days=30));
future_poll.was_published_recently();

python manage.py test polls

from django.test.utils import setup_test_environment;
setup_test_environment();

from django.test.client import Client;
client = Client();

# get a response from '/'
response = client.get('/');
# we should expect a 404 from that address
response.status_code;

# on the other hand we should expect to find something at '/polls/index'
# we'll use 'reverse()' rather than a hardcoded URL
from django.core.urlresolvers import reverse;
response = client.get(reverse('polls:index'));
response.status_code;

response.content;

# note - you might get unexpected results if your 'TIME_ZONE'
# IN 'settings.py' is not correct. If you need to change it,
# you will also need to restart your shell session
from polls.models import Poll;
from django.utils import timezone;
# create a Poll and save it
p = Poll(question="Who is your favorite Beatle?", pub_date=timezone.now());
p.save();
# check the response once again
response = client.get('/polls/index');
response.content;
response.context['latest_poll_list'];

package
python setup.py sdist
pip install --user django-polls/dist/django-polls-0.1.zip
c:\users\zhang\appdata\roaming\python\python27\site-packages\polls