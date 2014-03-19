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