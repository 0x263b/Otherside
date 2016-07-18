# Otherside for Twitter

[Otherside](https://otherside.site) creates a [Twitter List](https://twitter.com/lists) of the accounts someone follows, letting you see Twitter from their perspective.

Inspired by [this post](http://parkerhiggins.net/2015/12/a-twitter-list-of-somebody-elses-timeline/), and [twitter goggles](https://github.com/ardubs/goggles).

Also check out the [standalone command line version](https://gist.github.com/0x263b/7b391a1617fcbbabc57fb1e705884a11).


### Caveats

* Lists can only contain up to 5,000 accounts.
* Private accounts you don’t follow will be skipped.
* Twitter’s API has a rate limit on the number of GET requests that can be made in a 15 minute window.
* Twitter has a follow limit of [1,000 per day](https://support.twitter.com/articles/15364), and [5,000 total](https://support.twitter.com/articles/68916).
  * It *looks* like this applies to lists, but Twitter doesn't clarify.


### Running
* Create a new Twitter app → [https://apps.twitter.com/](https://apps.twitter.com/)
* Edit `config.ru` and add your app's consumer key and consumer secret, and create a secret for the cookie
