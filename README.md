# 5gRateMatchingTest
En este repositorio se muestran los diferentes archivos utilizados que permiten comprobar el funcionamiento de los módulos de Rate Matching junto al de Code Block Concatenation pertenecientes a la cadena de 5G.

Se muestran los siguientes archivos:  

  -**PRUEBA RATE MATCHING (char vector-OK).c**------------------>Código en C de la función de rate matching junto al code block concatenation implementados en ALOE. Copiar el siguiente código y ejecutar en un compilador C online. Se puede ejecutar en el siguiente compilador online: https://www.onlinegdb.com/online_c_compiler  
  
  -**TEST_RATEMATCHING.app**-------------------------------------->En la misma cadena de LTE se ha añadido el módulo de RATEMATCHING después del LTETURBOTX y antes del SCRAMBLING, de esta manera se podrá observar en ALOE como es el vector de entrada y el de salida de este mismo módulo, no prestando atención en el resto pertenecientes a LTE.  
  
  -**RATEMATCHING.params**---------------------------------------->En este mismo documento .params se muestran las diferentes variables modificables del RATEMATCHING dejando en todo momento la variable TBSLBRM=0, ya que TBSLBRM=1 no está habilitada.  

  -**PRUEBA_RATE_MATCHING_MATLAB.m**------------------------------>Código matlab adaptado del original de 5G Toolbox que ofrece Matlab.  
  
  -**Se observarán unos mismos resultados comparando PRUEBA_RATE_MATCHING_MATLAB.m y PRUEBA RATE MATCHING (char vector-OK).c. Posteriormente, se produce el traspaso del código en C a ALOE, donde se podrá comprobar su correcto funcionamiento.**  
  
  -**Por último se muestra el siguiente archivo: RATE_MATCHING.tar.gz, perteneciente a la implementación del código previo en ALOE. Para probar su correcto funcionamiento es necesario realizar una lectura previa del documento entregado por Atenea.**
