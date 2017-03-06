<?php
$chislo=3;
for ($i=1; $i < 1000 ; $i++) 
	{ 
		if ($i%5) 
			{	
				echo $i;
				$pos= strpos($i , $chislo);
					if ($pos===false) 
					{
					echo $pos ."<br>";
					}
			}	
	}
?>