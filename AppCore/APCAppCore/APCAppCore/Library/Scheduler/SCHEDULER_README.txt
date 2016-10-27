//  SCHEDULER_README.txt
//
//  Copyright (c) 2015, Apple Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1.  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  2.  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation and/or
//  other materials provided with the distribution.
//
//  3.  Neither the name of the copyright holder(s) nor the names of any contributors
//  may be used to endorse or promote products derived from this software without
//  specific prior written permission. No license is granted to the trademarks of
//  the copyright holders even if such marks are included in this software.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
//  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
//  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
//  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Please keep the "canonical examples" file, CanonicalScheduleExamples.json,
up to date, as you add and remove schedule features.

To test with that file:
-   uninstall the app from the device
-   copy and paste the contents of that file into the existing
    APHTasksAndSchedules.json file (or whatever file your app loads by
    by default)
-   run the app
-   see what's in the Activities screen
-   change your phone's system date FORWARD one day at a time, looking at
    the tasks that appear in the "Today" and "Yesterday" sections of the
    Activities screen.  The tasks themselves should describe when they should
    appear and vanish.

As of this writing, 2015-July-02, the rules are:
-   A task appears in the "Today" list until it expires.
-   When it expires, it moves to the "Yesterday" list for one day.
-   If you do a task on a given day, it appears with a green checkmark for the
    rest of that day, and then vanishes.
-   The task reappears in "Today" according to its schedule's repetition rules.

Tasks may have these properties:
-   taskTitle: a human-readable string.
-   taskID:  an ID string unique within this file.  In practice, many apps
    refer to task IDs in code to detect or enable various features.
-   taskFileName:  the name of a JSON file containing the intented content
    of that activity or survey.
-   taskClassName:  the name of the view controller to load for that task.
-   taskCompletionTimeString:  a helper message that appears beneath each
    task in the Activities screen, in a smaller font.

Schedules may have these properties.
-   scheduleType:  "once" or "recurring".
-   maxCount:  a positive integer.
-   scheduleString:  a cron expression specifying when the task appears
    on-screen.  All tasks appear in whole-day increments, but if you specify
    hours and minutes, the task will appear with a badge indicating how many
    copies of that task are required that day.
-   delay:  an ISO 8601 duration expression indicating a time to wait before the task
    appears on-screen.  If less than one day, there is no delay.
-   expires:  an ISO 8601 duration indicating when each instance of a task should move from the "Today" list to the "Not Completed by Yesterday" list.  If omitted, tasks never expire (if one-time tasks), or expire at the next recurrence (if repeating tasks).
-   interval:  an ISO 8601 duration expression indicating the time between occurrences of the task.  If less than one day, equates to 1 day.
-   times:  a JSON array of ISO 8601 times of day, every <interval> days.  You may also specify whole integers, representing hours of the day:  5, 12, 18, etc.
-   notes:  for debugging.
-   tasks:  a JSON array of one or more Task objects.
-   country: optional 2 letter country code, if not applied schedule is applied to all countries, if applied it's checked against APCAppDelegate:currentCountry and applied if they are equal, this value is not stored in coredata