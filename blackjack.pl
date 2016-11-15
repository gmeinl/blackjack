#!/usr/bin/perl
# cardstest.pl
use warnings;
use strict;

use Games::Cards;
use Scalar::Util qw(looks_like_number);

{
	print ("You quit with ", playgame(), " chips!");
}

sub playgame
{
	my $chips = 1000;
	# keep going until user quits or is broke.
	while ($chips>0){
		print ("You have $chips chips.  Place your bet!  Bet 0 to quit.");
		my $bet = <STDIN>;
		if(!looks_like_number($bet))
		{
			print ("$bet isn't a number!  Please bet some number of chips.\n");
		}
		elsif ($bet==0)
		{
			return $chips;
		}
		elsif ($bet>$chips)
		{
			print ("You don't have $bet chips!\n");
		}
		else
		{
			$chips = newHand($chips, $bet);
		}
	}
	print ("You're broke, game over!\n");
	return 0;
}

# deal a new hand and return the new chip total after the hand is over.
sub newHand
{
	my ($chips, $bet) = @_;
	
	my $Blackjack = new Games::Cards::Game; 
	# Create a new deck and shuffle
	my $Deck = new Games::Cards::Deck ($Blackjack, "Deck");
	$Deck->shuffle;
	
	my @Hands;
 
	my $playerhand = new Games::Cards::Hand ($Blackjack, "Player Hand");
	
	# Deal player hand
	$Deck->give_cards($playerhand, 2);
	my $playerScore = scoreHand($playerhand);
	print ($playerhand->print("short"), "\n");
	print ("Player score is: $playerScore \n"); 
	
	
	# deal dealer hand
	my $dealerhand = new Games::Cards::Hand ($Blackjack, "Dealer Hand");
	$Deck->give_cards($dealerhand, 1);
	print ($dealerhand->print("short"), "\n");
	
	# flags for operations during the hand
	my $playerBlackjack = 0;
	my $dealerBlackjack = 0;
	my $moreCards = 1;
	my $firstCard = 1;
	my $playerBust = 0;
	my $dealerBust = 0;
	
	# player blackjack
	if ($playerScore==21)
	{
		print ("You have a blackjack!\n");
		$playerBlackjack=1;
		# don't need to draw.
		$moreCards = 0;
	}
	
	while($moreCards)
	{
		blackjackHandMenu($firstCard);
		my $option = <STDIN>;
		
		if(!looks_like_number($option))
		{
			print ("$option isn't a number!  Please use the number options to select your move.\n");
		}
		# hit
		elsif ($option==1)
		{
			$Deck->give_cards($playerhand, 1);
			print ($playerhand->print("short"), "\n");
			$playerScore = scoreHand($playerhand);
			print ("New Player score is: $playerScore \n"); 
		}
		# stand
		elsif ($option==2)
		{
			
			$moreCards = 0;
		}
		# double
		elsif ($option==3)
		{
			# can only double on the first card
			if ($firstCard)
			{
				$Deck->give_cards($playerhand, 1);
				print ($playerhand->print("short"), "\n");
				$playerScore = scoreHand($playerhand);
				print ("New Player score is: $playerScore \n");
				
				# only can get one card, double bet if possible.  If not enough chips just bet all of them.
				$bet*=2;
				if ($bet>$chips)
				{
					print ("You don't have enough chips to cover a double.  Betting it all!\n");
					$bet = $chips;
				}
				$moreCards = 0;
			}				
			else
			{
				print ("You already drew a card and can't double! Choose hit or stand.\n");
			}
		}
		else
		{
			print ("Please select a valid option from the menu.\n");
		}
		# TODO split
		
		# player busts
		if ($playerScore>21)
		{
			print ("You bust!\n");
			$moreCards=0;
			$playerBust=1;
		}
		$firstCard=0;
	}
	
	# play dealer hand
	my $dealerScore = scoreHand($dealerhand);
	while ($dealerScore<17)
	{
		$Deck->give_cards($dealerhand, 1);
		$dealerScore = scoreHand($dealerhand);
		print ($dealerhand->print("short"), "\n");
		print ("Dealer has: $dealerScore \n");
	}
	print ($dealerhand->print("short"), "\n");
	print ("Dealer has: $dealerScore \n");
	if (scoreHand($dealerhand)>21)
	{
		print ("Dealer is bust!\n");
		$dealerBust = 1;
	}
	
	# pay blackjack at 3/2
	if ($playerBlackjack)
	{
		print ("You got a blackjack!  Paying out ", ($bet*1.5), " chips.");
		return $chips+($bet*1.5);
	}
	
	# busts and push
	if ($playerBust)
	{
		print ("You lose $bet chips.\n");
		return $chips-$bet;
	}
	if ($dealerBust)
	{
		print ("Paying out $bet chips.\n");
		return $chips+$bet;
	}
	if ($playerScore==$dealerScore)
	{
		print ("Push!  Nothing happens.\n");  
		return $chips;
	}
	
	# otherwise player wins if higher score than dealer
	$playerScore>$dealerScore ? print ("You win!  Paying out $bet chips.\n") : print ("You lose $bet chips.\n"); 
	$playerScore>$dealerScore ? return $chips+$bet : return $chips-$bet;
}

# options during a blackjack hand.  flags for first card to allow doubles and same value for splits.
sub blackjackHandMenu
{
	my ($firstCard, $sameValue) = @_;
	print ("1: Hit, 2: Stand", $firstCard? ", 3: Double":"", $sameValue? ", 4: Split":"", "\n");	
}

# scores a hand
sub scoreHand
{
	my ($hand) = @_;
	
	my @cards = @{$hand->cards()};	
	my $score = 0;
	my $aces = 0; # ace flag
	# add value of cards
	foreach (@cards)
	{
		my $cardValue = $_->value();
		if ($cardValue==1)
		{
			$aces++;
		}
		$score+=blackjackValue($cardValue);
	}
	# add 10 if aces and won't bust
	if ($aces&&($score<=11))
	{
		$score+=10;
	}
	return $score;
}

# add a single card's value
sub blackjackValue
{
	my ($cardValue) = @_;
	unless ($cardValue>=10)
	{
		return $cardValue;
	} 
	return 10;
}
