/*
Copyright (C) 2012 Web3Canvas. All Rights Reserved.
*/


/* Define the number of snow to be used in the animation */
const NUMBER_OF_snow = 30;

/* 
    Called when the "Falling snow" page is completely loaded.
*/
function init()
{
    /* Get a reference to the element that will contain the snow */
    var container = document.getElementById('snowContainer');
    /* Fill the empty container with new snow */
    for (var i = 0; i < NUMBER_OF_snow; i++) 
    {
        container.appendChild(createAsnow());
    }
}


/*
    Receives the lowest and highest values of a range and
    returns a random integer that falls within that range.
*/
function randomInteger(low, high)
{
    return low + Math.floor(Math.random() * (high - low));
}


/*
   Receives the lowest and highest values of a range and
   returns a random float that falls within that range.
*/
function randomFloat(low, high)
{
    return low + Math.random() * (high - low);
}


/*
    Receives a number and returns its CSS pixel value.
*/
function pixelValue(value)
{
    return value + 'px';
}


/*
    Returns a duration value for the falling animation.
*/

function durationValue(value)
{
    return value + 's';
}


/*
    Uses an img element to create each snow. "snow.css" implements two spin 
    animations for the snow: clockwiseSpin and counterclockwiseSpinAndFlip. This
    function determines which of these spin animations should be applied to each snow.
    
*/
function createAsnow()
{
    /* Start by creating a wrapper div, and an empty img element */
    var snowDiv = document.createElement('div');
    var image = document.createElement('img');
    
    /* Randomly choose a snow image and assign it to the newly created element */
    image.src = 'images/snow' + randomInteger(1, 6) + '.png';
    
    snowDiv.style.top = "-100px";

    /* Position the snow at a random location along the screen */
    snowDiv.style.left = pixelValue(randomInteger(0, 1000));
    
    /* Randomly choose a spin animation */
    var spinAnimationName = (Math.random() < 0.5) ? 'clockwiseSpin' : 'counterclockwiseSpinAndFlip';
    
    /* Set the -webkit-animation-name property with these values */
    snowDiv.style.webkitAnimationName = 'fade, drop';
    image.style.webkitAnimationName = spinAnimationName;
    
    /* Figure out a random duration for the fade and drop animations */
    var fadeAndDropDuration = durationValue(randomFloat(5, 11));
    
    /* Figure out another random duration for the spin animation */
    var spinDuration = durationValue(randomFloat(4, 8));
    /* Set the -webkit-animation-duration property with these values */
    snowDiv.style.webkitAnimationDuration = fadeAndDropDuration + ', ' + fadeAndDropDuration;

    var snowDelay = durationValue(randomFloat(0, 5));
    snowDiv.style.webkitAnimationDelay = snowDelay + ', ' + snowDelay;

    image.style.webkitAnimationDuration = spinDuration;

    // add the <img> to the <div>
    snowDiv.appendChild(image);

    /* Return this img element so it can be added to the document */
    return snowDiv;
}


/* Calls the init function when the "Falling snow" page is full loaded */
window.addEventListener('load', init, false);
