Directions for using Similar.exe

I. Setup

	1. Create a folder on your computer (say, C:\Programs\Similar)

	2. Unzip the Similar.zip file into that folder. 
	   (On a Windows machine, which is what you need anyway to run this program,
	   you should be able to click on Similar.zip with the non-dominant mouse button,
	   choose 'Open with' in the menu that pops up, and select 
	   'Compressed (zipped) folders'.)

If you're not using any diacritics, you just need to set up 2 files (see below): 
Oldfeat.txt and xxx.inv.

If you are using diacritics, you can still get away with just these files 
if you follow the directions for diacritics in Step III.

II. Oldfeat 
YOU CAN SKIP THIS STEP if you want to use the built-in feature system. 
If you want to use your own features and feature values (and even symbols), do this step.

	1. Make a backup copy of the original Oldfeat.txt and put it in another 
	folder.

	2. Open Oldfeat.txt (the copy you left in the Similar folder) using Notepad 
	(found under Startup\Accessories)

	3. The top row is the list of features, separated by commas and tabs. 
	Replace them with the features you want to use.

	4. Don't erase the "NoMoreFeatures" at the end of the row.

	5. The other rows are segments. The first item in the row is the symbol for 
	the segment (to be viewed in SILDoulosIPA93, ultimately). Replace these 
	with the symbols you want to use.

	6. The second item in the row is a keyboard code. Just leave it alone or put 
	000--they aren't used for anything.

	7. The other items are values for the features in the first row. The features 
	are in the same order, but they won't line up. Replace these with the 
	feature values you want.

	8. Leave the "EndOfLine"s and the "NoMoreSegments".

	9. Make sure not to insert any extra spaces or tabs or returns.

	10. Diacritics: if your inventory contains any segments with diacritics,
	you should include those segments in the file so that they appear BEFORE their
	diacriticless counterparts. Otherwise, the program will try to use its own
	diacritic system--which won't work if you've modified the feature system 
	(you'd have to modify some other, very user-unfriendly files). 

	11. Except for the above, the order of the segments doesn't matter.
	The program will run fastest if you include only the segments you'll
	be using in your inventory, and only the features that aren't redundant,
	but extra segments and features won't hurt (just slow things down). 
	Computers have gotten a lot faster since I wrote this program, so speed 
	is probably not a worry any more.

	12. Save the file (as PLAIN TEXT) and exit. Do not change the name 
	from Oldfeat.txt

III. Inventories (If you have FeaturePad on your computer, you can use its "Create a 
Phoneme Inventory" menu item for this step).

	1. Make a backup of one of the original xxx.inv files.

	2. Open the original copy of that file in Notepad. Take a look at the file.
	It represents a (possibly partial) phoneme inventory, laid out as a partial 
	IPA chart. The segments are listed one row at a time, with "None" for 
	missing slots and "EndOfRow" at the end of each row. Try drawing the
	grid for the inventory you have opened to see how it works.

	3. Now draw (on paper) the grid for the inventory you will be looking at. 
	Using the original file for guidance, replace the segments there with the 
	segments of your inventory.

	4. The last row of consonants ends with "EndOfConsonants" instead of
	"EndOfRow".

	5. The "other" segments of the IPA (like w) are in just one column, so 
	there are no "None"s and no "EndOfRow"s. Even if you have no "other"
	segments, keep the "EndOfOthers". 

	6. Even if you have no vowels, you 
	may need to put in one dummy row ("None" return "EndOfRow") after 
	the "other" segments.

	7. End with "NoMorePhones"

	8. Make sure to include members of the inventory that bear diacritics.
	If you don't have SILIpaDoulos93, you can make up diacritics (e.g., d5
	for dental [d]--just don't put any spaces in between the d and the 5).

	9. Make sure every segment in your inventory was included in Oldfeat.txt

	10. Save the file as plain text. Name it xxx.inv, where xxx is whatever you
	want. Exit Notepad.

IV. Running the program

	1. Double-click on Similar.exe.

	2. Pick a phoneme inventory and click Open. Now click 'Calculate Similarity' 
	   on the window that appear.

	3. Be patient while the program is running. It may take 60 seconds.
	[Probably much less nowadays]

	4. When it's done (the top of the windo says 'Similarity calculations for 
	   xxx.inv complete!'), you can close the window.

	5. Now you've got 2 new files. Open xxx.sbs with Notepad or Excel (if Excel, 		use 'space' as the delimiter). This is a list of all the distinct
	subsets of segments found. Even if a subset could be defined by more
	than one set of feature requirements, it is listed only under the first set
	of requirements that was found. You can use this file to make sure
	you used the features you meant to.

	6. Open xxx.stb with Notepad or Excel (again, if Excel, use 'space' as the 		delimiter). This is a list of pairwise similarity
	scores for all the segments in xxx.inv. The 3rd column is #ofsharedsubsets
	/#ofsharedandunsharedsubsets. If you use Excel, you can sort by the last
	column (similarity score), make plots, etc.

You're done.