To get started, run

1. ``docker compose up``
Should run on localhost 3000 after a bit of start time.

To check if it works, 
1. log in with default@mail.com and Password123 or make your own account.
2. Pick the demo key option when prompted
3. then go to contacts, add a contact you want to recieve email to.
4. View that contact, click to add tag to it
5. create tag
6. assign tag to it
7. go to the automatoons section 
8. create new automation
9. pick your tag as a trigger
10. keep delay at 0
11. make sure it is active
12. confirm creation, it should notify already that a mail was sent

Any issues?
try ``docker compose exec web bin/rails db:migrate`` when the docker container is running, and then try open the page again.

to do tests on the docker container, run
``docker compose exec web bin/rails test``