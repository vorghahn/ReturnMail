
ReturnMail -- Created by Verlange

ReturnMail is based on ForwardMail by Tageshi and also Postal.

It simply returns the mail and attachements to the original sender. It will prioritise using the default in-game return function if available.
If not it will retrieve the items, draft a new mail, attache the items and resend it.
This can be triggered by pressing the "Force Return" button inside each mail or by pressing the backwards arrow on the main mailbox view.
Holding 'Alt' or 'Shift' down whilst clicking acts as a modify and will draft but not send the reply allowing you to modify the return.

Known issue(s):
Can process fast enough to trigger mail desync resulting in a pause. Waiting a few seconds and hitting the send button will restart the process.

Release Log:
v1.3.0
- Fix for stackable items breaking the return process.
- Fix for easy returns breaking the iteration.

v1.2.0
- Bulk mail return function added. Returns mail based on time remaining.

v1.1.1
- Added error catch for the receiver having a full mail box.

v1.1.0
- Tooltip fix
- Added shift and alt modifiers.
- Created readme