# Libras Alphabet Detector
Este projeto consiste em um aplicativo de reconhecimento real-time do alfabeto em libras para iOS, desenvolvido em Swift, com o objetivo de explorar e estudar ferramentas como CoreML, CreateML, Vision e AVFoundation.
O aplicativo é capaz de detectar em tempo real 21 letras do alfabeto, em Libras, e exibir a letra correspondente em um componente de texto.

![rpreplay-final1680465453_Bb9d2VWv](https://user-images.githubusercontent.com/20246441/229413596-19906b5d-5325-4a80-951a-2151b55d5b96.gif)

## Como utilizar este projeto
Para utilizar este projeto, é necessário ter o Xcode instalado em seu computador. Abra o projeto no Xcode e execute-o em um dispositivo iOS. O detector iniciará a captura de vídeo da câmera e detectará os gestos de mão correspondentes às letras do alfabeto de Libras.

## Modelo de detecção
O modelo utilizado no projeto foi desenvolvido utilizando a ferramenta [CreateML](https://developer.apple.com/machine-learning/create-ml/) da Apple. Para o treinamento, foi utilizado um [dataset](https://www.kaggle.com/datasets/williansoliveira/libras) aberto disponível na plataforma Kaggle, com 75% da base para treino e 25% para teste, gerando um modelo com ~97% de acurácia.

## Contribuindo
Se você deseja contribuir para este projeto, fique à vontade para enviar um pull request com melhorias ou correções de bugs.
