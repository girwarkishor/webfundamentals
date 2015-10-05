---
layout: shared/narrow
title: "Memory waste"
description: "Test for inefficient memory use."
notes:
  styling:
    - Styling will come later
published_on: 2015-09-28
updated_on: 2015-09-28
order: 5
translation_priority: 0
---

Janky animations aren't the only cause of poor performance in web apps and pages. Another major culprit is inefficient memory use and, as you might guess, our news aggregator app is guilty of that as well.

When a story headline in the main list is clicked, the app builds the story content, adds it to the page, and slides it into view. It's the "adds it to the page" part that needs examining. Conveniently, the function that handles a story click is called `onStoryClick`. Let's have a look at it.

```javascript
function onStoryClick(details) {
  var storyDetails = $('sd-' + details.id);
  // Wait a little time then show the story details.
  setTimeout(showStory.bind(this, details.id), 60);
  // Create and append the story. A visual change...
  // perhaps that should be in a requestAnimationFrame?
  // And maybe, since they're all the same, I don't
  // need to make a new element every single time? I mean,
  // it inflates the DOM and I can only see one at once.
  if (!storyDetails) {
    if (details.url)
      details.urlobj = new URL(details.url);
    var comment;
    var commentsElement;
    var storyHeader;
    var storyContent;
    var storyDetailsHtml = storyDetailsTemplate(details);
    var kids = details.kids;
    var commentHtml = storyDetailsCommentTemplate({
      by: '', text: 'Loading comment...'
    });
    storyDetails = document.createElement('section');
    storyDetails.setAttribute('id', 'sd-' + details.id);
    storyDetails.classList.add('story-details');
    storyDetails.innerHTML = storyDetailsHtml;
    document.body.appendChild(storyDetails);
    commentsElement = storyDetails.querySelector('.js-comments');
    storyHeader = storyDetails.querySelector('.js-header');
    storyContent = storyDetails.querySelector('.js-content');
    var closeButton = storyDetails.querySelector('.js-close');
    closeButton.addEventListener('click', hideStory.bind(this, details.id));
    var headerHeight = storyHeader.getBoundingClientRect().height;
    storyContent.style.paddingTop = headerHeight + 'px';
    if (typeof kids === 'undefined')
      return;
    for (var k = 0; k < kids.length; k++) {
      comment = document.createElement('aside');
      comment.setAttribute('id', 'sdc-' + kids[k]);
      comment.classList.add('story-details__comment');
      comment.innerHTML = commentHtml;
      commentsElement.appendChild(comment);
      // Update the comment with the live data.
      APP.Data.getStoryComment(kids[k], function(commentDetails) {
        commentDetails.time *= 1000;
        var comment = commentsElement.querySelector(
            '#sdc-' + commentDetails.id);
        comment.innerHTML = storyDetailsCommentTemplate(
            commentDetails,
            localeData);
      });
    }
  }
}
```

After the first group of variable declarations, notice the four lines that construct the variable `storyDetails`, setting its element type, attributes, and content. Directly after that, note that `storyDetails` is added to the DOM as a new node with the `appendChild` method.

At first, that isn't necessarily a problem, but it becomes increasingly wasteful as the app is used. Of course, the user only ever sees one story at a time, but the new nodes that are created for each viewed story are never discarded. After a few clicks, the DOM will be cluttered with abandoned nodes that take up memory and slow down the app -- and the longer the app is used, the worse its performance will get.

>**Discussion: appendChild, removeChild, and replaceChild**
>
>If you understand the problem we've just described, your first thought for a potential fix might be to simply remove the node after the story is viewed (or, more accurately, before the next one is viewed) with `removeChild` -- or replacing it with `replaceChild` -- thereby avoiding the clutter of multiple abandoned nodes.
>
>That's not an unreasonable idea, but both methods still require a significant amount of DOM work by the browser, manipulating the DOM tree to add and remove nodes every time a story is clicked.
>
>Let's consider whether we can accomplish the same thing without manipulating the DOM tree at all.</span>

A better way to accomplish this feature is to create just one permanent `storyDetails` node earlier in the script to hold the current story, and then use the trusty `innerHTML` property to reset its content each time instead of creating a new node. So this section of code

```javascript
    storyDetails = document.createElement('section');
    storyDetails.setAttribute('id', 'sd-' + details.id);
    storyDetails.classList.add('story-details');
    storyDetails.innerHTML = storyDetailsHtml;
    document.body.appendChild(storyDetails);
```

can be simplified to this.

```javascript
    storyDetails.setAttribute('id', 'sd-' + details.id);
    storyDetails.innerHTML = storyDetailsHtml;
```

That change will undoubtedly improve long term performance, but it doesn't do anything for us in the short term. We still need to finish addressing the story slide-in/out issue.