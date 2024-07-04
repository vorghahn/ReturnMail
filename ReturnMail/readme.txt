
ReturnMail -- Created by Tageshi

-------------------------------------------------------------------------
1. WHAT IS "ReturnMail"?
-------------------------------------------------------------------------

ReturnMail is a simple and powerful mailing addon which let you 
transfer Dozens or Hundreds of items from your inbox to other characters 
with a single slash command.

Also ReturnMail provides other mail related commands such as fetching 
all AH mails too. 
There are three slash-commands /forward and /sendmail and /openmail.
(/fw, /mail, /open for short)

Slash Command Usage: 
 /forward [recipient] [#] [itemlink] ...
   or /fw [recipient] [#] [itemlink] ...
   to transfer specific items from your inbox (and your bags too) to other character.
   Prefix number [#] is to limit sending item quantity to a specific number.

 /sendmail [recipient] [#] [itemlink] ...
   or /mail [recipient] [#] [itemlink] ...
   to transfer specific items from your bags to other character.
   Prefix number [#] is to limit sending item quantity to a specific number.

 /openmail [#] [itemlink] ...
   or /open [#] [itemlink] ...
   to loot specific items from your inbox.
   Prefix number [#] is to limit looting item quantity to a specific number.

 /openmail
   or /open
   to loot items and money from all AH mails from your inbox.

GUI:
- [Open AH] button in Inbox tab of Mailbox
 This button is same as /openmail slash-command.

- [Forward All] button in SendMail tab of Mailbox
 This button is same as /forward slash-command.

- [Forward To] button in OpenMail window of Mailbox.
 This button will pick up attachments of the mail currently opened, 
 and then arrange SendMail tab with all attachments for forwarding.



-------------------------------------------------------------------------
2. HOW TO USE "ReturnMail"?
-------------------------------------------------------------------------

Assuming that you have bought hundreds of Hypnotic Dusts at AH, 
and want to store all of them in the bank-alt's inbox.

Open Mailbox window and just type:
      /fw YOURBANKALT [Hypnotic Dust]
(also you can shift-click the item to input item link here.)

If you prefer GUI operation, there is another way.
 1. Open Mailbox window.
 2. Select Send Mail Tab.
 3. Input recipient name in To: field.
 4. Right-click one of [Hypnotic Dust] in your bag to place into attachment slot.
 5. Push [Forward All] button (instead of normal [Send] button!)

Now enjoy watching all Hypnotic Dusts are automatically looted
one by one and sended away to your alt forming 12 stacks each mail.
It's super fast!

If your inbox has overflaws (more than 50 mails), 
ReturnMail will wait for refresh with one minute timer until more mails 
will be shown, and then automatically continues its job.


ReturnMail only provide GUI for tiny subset of its slash-commands.
(More GUI function planned for later version!)
So you need to rely on manually typing slash command OR using macro. 
You can write multiple lines of slash commands in a macro; 
ReturnMail will correctly accept all commands at once and run them one by one.

For example, when you are buying lots of [Obsidium Ore] and [Elementium Ore] to 
craft [Stormforged Shoulders] and planning to disenchant it into [Heavenly Shard] 
with another alt, you can use a single same macro like below to use for 
all the three alts.

#####_START_OF_MACRO_#####
/fw YOURMINER [Obsidium Ore]
/fw YOURMINER [Elementium Ore]
/fw YOURBLACKSMITH [Obsidium Bar]
/fw YOURBLACKSMITH [Elementium Bar]
/fw YOURDISENCHANTER [Stormforged Shoulders]
#####_END_OF_MACRO_#####

Tips: If the recipient is yourself, that command will be safely skipped 
and nothing happen. That's why you don't need three different versions 
of this macro. Just write all the commands within a single macro.


If you don't have enough free slot for your macro icons, 
I suggest using other addons to make more macros.
My another addon BindPad, for example, will allow you to create 
almost unlimited number of macros within it. 
(Though you cannot put those BindPad Macros into actionbar,
 you can directly bind keys instead.)


-------------------------------------------------------------------------
3. DETAILS AND MORE INFORMATIONS
-------------------------------------------------------------------------

Sending and receiving mails is such simple and easy job at first glance.
But actually it is very difficult to correctly handle mailing APIs of WoW.
If you call these APIs too quickly, it fail and
"Internal Mail Database Error" happens.

Thus most current addons manage to avoid this error by waiting for interval 
time between API calls and throttling, 
for example looting one mail per 0.5 sec or so.

Whereas ReturnMail can precisely handle all mailing related events to 
make it run faster and error-proof. Related events are listed below:

MAIL_SEND_SUCCESS    : After SendMail call.
MAIL_SEND_INFO_UPDATE: While(!) ClickSendMailItemButton() call.
MAIL_SUCCESS         : After MAIL_SEND_SUCCESS and TakeInboxItem/TakeInboxMoney
ITEM_PUSH            : After TakeInboxItem
BAG_UPDATE           : After all TakeInboxItem indicating SendMail is possible.
PLAYER_MONEY         : After TakeInboxMoney
MAIL_INBOX_UPDATE    : After any change in inbox. Most notably when GetInboxInvoiceInfo is available
MAIL_FAILED          : Rerely happens.
UI_ERROR_MESSAGE     : Rerely happens.

For handling these events, I am using lua's coroutines as threads.
Look at how rm.WaitFor(event) function neatly works if you are interested in details.


-------------------------------------------------------------------------
4. WHERE CAN I GET LATEST VERSION?
-------------------------------------------------------------------------

You can get latest version of ReturnMail from www.wowinterface.com:

http://www.wowinterface.com/downloads/info21163-ReturnMail.html

Or from Curse:

http://www.curse.com/addons/wow/ReturnMail


-------------------------------------------------------------------------
5.  CHANGES
-------------------------------------------------------------------------

Version 0.4.3
- Added slash command option "-toggle" to hide buttons on MailFrame.
  Type
   /fw -toggle Forward All
   /fw -toggle Forward To
   /fw -toggle Open AH
  to hide/show the buttons.

Version 0.4.2
- Fixed item messages of "Open AH" button.
- Fixed some lua errors by addon conflict.


Version 0.4.1
- Fixed bug /fw may fail on arithmetic on a nil value.
  (because GetItemInfo won't return values when you have none in your bag.)
- Fixed bug /fw sometimes didn't correctly marge smaller stacks before sending.


Version 0.4
- Slash-commands now accept a quantity prefix-number to send/receive specific number of items.
  Ex.) /fw Tageshi 5 [Elementium Ore] 10 [Obsidium Ore]
       /mail Tageshi 2 [Stormforged Shoulders]
       /open 5 [Hypnotic Dust]
- /forward now always marge stacks to the maximum item count each stack.


Version 0.3.1
- Fixed "script run too long" error.
- Fixed bug: [Forward To] sometimes looted wrong mails.


Version 0.3
- Updated for Mist of Pandaria beta 15799.
- Added [Forward To] button in OpenMail window.


Version 0.2
- Added [Open AH] button in Inbox tab.
- Added [Forward All] button in SendMail tab.


Version 0.1
- Initial release.

