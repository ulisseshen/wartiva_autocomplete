# Investigation Report: Overlay Positioning in Multiline `TextFormField`

Demo Web: [click here](https://ulisseshen.github.io/wartiva_autocomplete/)

## Issue Overview  

The objective of this task was to ensure that the suggestion popup correctly follows the cursor in a multiline `TextFormField`. However, during the investigation, we encountered challenges related to cursor positioning and overlay alignment, particularly when dealing with multiple lines of text.

### Steps to Reproduce:  

1. Type "banana." in the input field; suggestions will appear.  
2. Select a suggestion after each "." to trigger another suggestion.  
3. Continue this process until the text spans at least four lines.  
4. Observe that the popup does not always align correctly with the cursor.  

## Investigation & Findings  

- The primary issue appears to stem from how Flutter's `RenderEditable` calculates cursor positioning. The internal logic in `editable.dart` is responsible for rendering the caret (cursor), and its behavior varies based on text length, line breaks, and font metrics.  
- The overlay's positioning works **closer to expectations when using Flutter's default fonts**, where it consistently appears below the cursor after inserting `.`.  
- However, with **custom fonts**, the overlay may shift slightly due to variations in line heights, text scaling, and character spacing. This suggests that font rendering differences impact the accuracy of `getLocalRectForCaret`.  

## Challenges  

- **Font Dependency:** Different fonts influence the caret's reported position, requiring additional logic to handle variations dynamically.  
- **Multiline Complexity:** As text spans multiple lines, determining the correct offset for the popup requires a deeper understanding of how Flutter manages text layout.  
- **Rendering Pipeline:** The overlay update relies on `PostFrameCallback`, but Flutter may not always recalculate text positions in real time, leading to occasional inconsistencies.  

## Next Steps  

1. **Deep dive into [`editable.dart`](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/src/rendering/editable.dart)** to understand and refine how `RenderEditable` calculates caret positions.  
2. **Investigate overlay positioning across different fonts** to create a more adaptive solution.  
3. **Improve the positioning logic** to dynamically adjust based on text layout changes.  
4. **Test across various screen densities and devices** to ensure consistency.  

## Final Thoughts  

Due to the complexity of this issue and the need for in-depth research, we were unable to fully resolve the problem within the allocated **three-day timeframe**. However, given the novelty of this challenge in Flutter, additional time would be necessary to refine the implementation and deliver a robust solution.  

The findings from this investigation provide valuable insights and a clear path forward for implementing an autocomplete overlay that is both functional and reliable in Flutter applications.  
