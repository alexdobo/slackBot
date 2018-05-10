This slackbot of based off [markwragg/Powershell-SlackBot](https://github.com/markwragg/Powershell-SlackBot). 

All of the authentication and other sensitive variables are located in the ./variables folder. 

[respondToMessage.ps1](respondToMessage.ps1) responds to the following commands:
- Tell me a **joke**
    - Returns a Chuck Norris joke from the [Chuck Norris Joke API](http://api.icndb.com/jokes/random)
- Give me an **excuse**
    - Returns an excuse from [this API](http://pages.cs.wisc.edu/~ballard/bofh/excuses)
- Show me a **dog photo**
    - Returns an attachment with a photo of a dog from [The Dog API](http://api.thedogapi.co.uk/v2/dog.php)
- What is the **time**?
    - Returns the time 
- **Who's online**?
    - Returns what IP Addresses are currently online by getting all DHCP reservations, and pinging all of them to see if they are up

ToDo:
 - Convert to morse code and back
 - Other random comical things
 - Make the code less bad
