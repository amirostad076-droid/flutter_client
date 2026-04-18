import 'dart:math';

class SplashQuote {
  const SplashQuote({required this.text, required this.source});
  final String text;
  final String source;
}

const List<SplashQuote> _baseSplashQuotes = <SplashQuote>[
  SplashQuote(text: "Aren't you supposed to be sleeping?", source: 'kitkatz'),
  SplashQuote(
    text:
        'After careful consideration, we have decided we did, in fact, need loading lines.',
    source: 'vky',
  ),
  SplashQuote(
    text: "There is no cloud... only other people's computers.",
    source: 'Siliconic',
  ),
  SplashQuote(
    text:
        'Did you know that Fluxer spelled backwards makes no sense? Why would you do that?',
    source: 'jackzie',
  ),
  SplashQuote(
    text: 'Have you considered touching grass while you wait?',
    source: 'Lilith',
  ),
  SplashQuote(
    text:
        "Unfortunately, it doesn't run on regular unleaded gasoline. It requires something with a little more kick. Plutonium.",
    source: 'Cookie',
  ),
  SplashQuote(text: '9/10 dentists recommend Fluxer.', source: 'Hugopuntocom'),
  SplashQuote(text: 'Is this thing on?', source: 'Pufty'),
  SplashQuote(
    text: 'Now supports sending messages over the Internet!',
    source: '99',
  ),
  SplashQuote(
    text:
        'Flux capacitors use 99.99% less water than your typical AI data centre!',
    source: 'snappyapple632',
  ),
  SplashQuote(text: 'No soldering skills required!', source: '99'),
  SplashQuote(text: 'Removed Herobrine.', source: 'Manfre'),
  SplashQuote(
    text: 'Please enjoy this loading quote while you wait.',
    source: 'illspirit',
  ),
  SplashQuote(
    text:
        "Fluxer is 100% powered by flux capacitors. And furries. We don't forget about the furries.",
    source: 'jb',
  ),
  SplashQuote(text: 'Unable to decrypt loading quote.', source: 'SteveLinkNoah'),
  SplashQuote(
    text: "Remember to hydrate! Or don't, I'm not the boss of you.",
    source: 'jb',
  ),
  SplashQuote(
    text: 'Congratulations! This is the special rare loading screen message!',
    source: 'jb',
  ),
  SplashQuote(text: 'Nu \u00e4r det dags f\u00f6r en fika.', source: 'Chip'),
  SplashQuote(
    text: "Is Fluxer loading? Why are you asking me? I'm just a loading screen!",
    source: 'Caus',
  ),
  SplashQuote(text: 'Welcome back to 2015!', source: 'Pan'),
  SplashQuote(text: 'Connecting to irc.fluxer.com:6667...', source: 'viriona'),
  SplashQuote(text: "Wait, hold on, I'm not ready yet!", source: 'Vee'),
  SplashQuote(text: "Feel that? That's Fluxer.", source: 'TheFastestBoy'),
  SplashQuote(
    text: 'The real fluxer was the friends we made along the way.',
    source: 'viriona',
  ),
  SplashQuote(
    text: 'Is Fluxer an instrument? No, Fluxer is a communication platform.',
    source: 'Comfy_Deer',
  ),
  SplashQuote(text: "Hi! I'm a loading screen!", source: 'jackzie'),
  SplashQuote(text: '3 Billion Devices Run Fluxer.', source: 'jackzie'),
  SplashQuote(
    text: 'To connect or not to connect, that is the question.',
    source: 'Tea',
  ),
  SplashQuote(text: 'Please do not the fluxer.', source: 'Chris'),
  SplashQuote(text: 'I am the one who fluxes.', source: 'Anonymous'),
  SplashQuote(
    text: 'Installing Fluxer on the nearest smart fridge...',
    source: 'TyphonBagrid',
  ),
  SplashQuote(text: 'Ya like Jazz?', source: 'catnaros'),
  SplashQuote(
    text:
        "If it smells like chicken, you're holding the soldering iron wrong.",
    source: 'viriona',
  ),
  SplashQuote(text: 'Everything is in flux.', source: 'Alyx'),
  SplashQuote(text: 'Happy new year 1999!', source: '99'),
  SplashQuote(text: 'Heating up the engine.', source: 'Ray'),
  SplashQuote(text: 'Pong!', source: 'Cookie'),
  SplashQuote(text: "Everyday I'm fluxin' it.", source: 'Liminalis'),
];

List<SplashQuote> buildSplashQuotes() {
  final List<SplashQuote> quotes = List<SplashQuote>.from(_baseSplashQuotes);
  quotes.add(
    SplashQuote(
      text:
          'Your odds of landing on this particular loading quote were 1 in ${quotes.length + 1}.',
      source: 'vky',
    ),
  );
  return quotes;
}

SplashQuote pickRandomSplashQuote() {
  final List<SplashQuote> quotes = buildSplashQuotes();
  final int quoteIndex = Random().nextInt(quotes.length);
  return quotes[quoteIndex];
}
