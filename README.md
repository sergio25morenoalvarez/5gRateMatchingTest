# 5gRateMatchingTest
En este repositorio se muestran los diferentes archivos utilizados para comprobar el funcionamiento del módulo de Rate Matching perteneciente a 5G.

Se muestran los siguientes archivos:  

  -**PRUEBA RATE MATCHING (char vector-OK).c**------------------>Código en C de la función de rate matching junto al code block concatenation implementados en ALOE. Copiar el siguiente código y ejecutar en un compilador C online. Se puede ejecutar en el siguiente compilador online: https://www.onlinegdb.com/online_c_compiler  
  
  -**TEST_RATEMATCHING.app**-------------------------------------->En la misma cadena de LTE se ha añadido el módulo de RATEMATCHING después del LTETURBOTX y antes del SCRAMBLING, de esta manera se podrá visionar como es el vector de entrada y el de salida de este mismo módulo, no prestando atención en el resto pertenecientes a LTE.  
  
  -**RATEMATCHING.params**---------------------------------------->En este mismo documento .params se muestran las diferentes variables modificables del RATEMATCHING.  

  -**PRUEBA_RATE_MATCHING_MATLAB.m**------------------------------>Código matlab adaptado del original de 5G Toolbox que ofrece Matlab.  
  
  -**Se observarán unos mismos resultados comparando PRUEBA_RATE_MATCHING_MATLAB.m y PRUEBA RATE MATCHING (char vector-OK).c. Posteriormente, se produce el traspaso del código en C a ALOE, donde se podrá comprobar su correcto funcionamiento.
