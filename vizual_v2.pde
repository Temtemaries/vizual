import ddf.minim.*;
import ddf.minim.analysis.*;
 
Minim minim;
AudioPlayer song;
FFT fft;

// Переменные, которые определяют "зоны" спектра
// Например, для низких, мы берем только первые 4% от всего спектра
float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20;   // 20%

//Осталось 64% спектра, которые возможно, не будут использоваться. 
// Эти значения, как правило, слишком высокие для человеческого уха.

// Значения баллов для каждой зоны.
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Значения предыдущих, чтобы смягчить сокращение.
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Значение для смягчения.
float scoreDecreaseRate = 25;

// Кубики, которые появляются в пространстве.
int nbCubes;
Cube[] cubes;

//Линии, которые появляются по бокам.
int nbMurs = 500;
Mur[] murs;
 
void setup()
{
 fullScreen(P3D); //Отображение в 3D на весь экран.
  background(0);
  minim = new Minim(this);
  song = minim.loadFile("song.mp3");
  fft = new FFT(song.bufferSize(), song.sampleRate());
  song.play(0);
  
//Куб в полосе частот.
  nbCubes = (int)(fft.specSize()*specHi);
  cubes = new Cube[nbCubes];
  
  //Реализация объектов:
  
//Массив для стен.
  murs = new Mur[nbMurs];
//Массив для кубов.
  for (int i = 0; i < nbCubes; i++) {
   cubes[i] = new Cube(); 
  }
  
 //Создания стен.
//Левые стены.
  for (int i = 0; i < nbMurs; i+=4) {
   murs[i] = new Mur(0, height/2, 10, height); 
  }
  
 //Стена посередине.
  for (int i = 1; i < nbMurs; i+=4) {
   murs[i] = new Mur(width, height/2, 10, height); 
  }
  
  //Нижние стены.
  for (int i = 2; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, height, width, 10); 
  }
  
//Верхние стены.
  for (int i = 3; i < nbMurs; i+=4) {
   murs[i] = new Mur(width/2, 0, width, 10); 
  }
}
 
void draw()
{
  //Продвижение песни.Для каждого "кадра" из песни...
  fft.forward(song.mix);
  
//Вычисление "оценки" (мощности) для трех категорий частот:

//Во-первых, сохранение старых значений:
  oldScoreLow = scoreLow;
  oldScoreMid = scoreMid;
  oldScoreHi = scoreHi;
  
 //Сброс значений:
  scoreLow = 0;
  scoreMid = 0;
  scoreHi = 0;
 
//Вычислить новые оценки мощности частот:
  for(int i = 0; i < fft.specSize()*specLow; i++)
  {
    scoreLow += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
  {
    scoreMid += fft.getBand(i);
  }
  
  for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
  {
    scoreHi += fft.getBand(i);
  }
  
//Смягчить запуск: 
  if (oldScoreLow > scoreLow) {
    scoreLow = oldScoreLow - scoreDecreaseRate;
  }
  
  if (oldScoreMid > scoreMid) {
    scoreMid = oldScoreMid - scoreDecreaseRate;
  }
  
  if (oldScoreHi > scoreHi) {
    scoreHi = oldScoreHi - scoreDecreaseRate;
  }
  
 //Объем для всех частот, в то время, для более высоких звуков:
//Это позволяет анимации двигаться быстрее, чтобы звуки более высоких частот не были заметны.
  float scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
  
  //Изменение цвета экрана в зависимости от частот: 
  background(scoreLow/100, scoreMid/100, scoreHi/100);
   
 //Куб для каждой полосы частот:
  for(int i = 0; i < nbCubes; i++)
  {
    //Значение полосы частот: 
    float bandValue = fft.getBand(i);
    
    //Распределение звука: красный цвет-для басов, зеленый для средних звуков и синий - для высоких. 
//Непрозрачность определяется объемом полосы и общим объемом.
    cubes[i].display(scoreLow, scoreMid, scoreHi, bandValue, scoreGlobal);
  }
  
 
  
  //Прямоугольные стены. 
  for(int i = 0; i < nbMurs; i++)
  {
   //Присваивается каждой стене ленты, и посылает ей свою силу.
    float intensity = fft.getBand(i%((int)(fft.specSize()*specHi)));
    murs[i].display(scoreLow, scoreMid, scoreHi, intensity, scoreGlobal);
  }
}

//Класс для кубов:
class Cube {
  //Положение Z максимальное.
  float startingZ = -10000;
  float maxZ = 1000;
  
  //Значения позиции куба:
  float x, y, z;
  float rotX, rotY, rotZ;
  float sumRotX, sumRotY, sumRotZ;
  
 //Конструктор.
  Cube() {
    //Разместить куб в случайном месте:
    x = random(0, width);
    y = random(0, height);
    z = random(startingZ, maxZ);
    
    //Дать кубу случайную ротацию:
    rotX = random(0, 1);
    rotY = random(0, 1);
    rotZ = random(0, 1);
  }
  
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
    //Выбор цвета и непрозрачность определяется интенсивностью (объемом ленты)
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, intensity*5);
    fill(displayColor, 255);
    
    //Цвет линии, которые исчезают с интенсивностью отдельного куба.
    color strokeColor = color(255, 150-(20*intensity));
    stroke(strokeColor);
    strokeWeight(1 + (scoreGlobal/300));
    
    //Создание матрицы для выполнения поворотов, расширения.
    pushMatrix();
    
    //Перемещение:
    translate(x, y, z);
    
    //Расчет вращения в зависимости от интенсивности кубов:
    sumRotX += intensity*(rotX/1000);
    sumRotY += intensity*(rotY/1000);
    sumRotZ += intensity*(rotZ/1000);
    
    //Применение вращения:
    rotateX(sumRotX);
    rotateY(sumRotY);
    rotateZ(sumRotZ);
    
    //Создание куба, размер переменной, в зависимости от интенсивности куба.
    box(100+(intensity/2));
    
    popMatrix();
    
    //Перемещение по Z:
    z+= (1+(intensity/5)+(pow((scoreGlobal/150), 2)));
    
    //Вернуть куб назад, когда его не видно:
    if (z >= maxZ) {
      x = random(0, width);
      y = random(0, height);
      z = startingZ;
    }
  }
}


//Класс для просмотра линии по бокам:
class Mur {
  //Минимальное положение и максимальное Z:
  float startingZ = -10000;
  float maxZ = 50;
  
  //Значения позиции:
  float x, y, z;
  float sizeX, sizeY;
  
  //Конструктор:
  Mur(float x, float y, float sizeX, float sizeY) {
    this.x = x;
    this.y = y;
    this.z = random(startingZ, maxZ);  
    
//Определяет размер(стены верхняя и нижняя отличаются по размеру от боковых):
    this.sizeX = sizeX;
    this.sizeY = sizeY;
  }
  
 //Функция отображения:
  void display(float scoreLow, float scoreMid, float scoreHi, float intensity, float scoreGlobal) {
//Цвет определяется низким, средним и высоким звуком:
//Прозрачность определяется общим объемом:
    color displayColor = color(scoreLow*0.67, scoreMid*0.67, scoreHi*0.67, scoreGlobal);
    
   //Содержание строки вдалеке, чтобы создать иллюзию тумана
    fill(displayColor, ((scoreGlobal-5)/1000)*(255+(z/25)));
    noStroke();
    
//Первая полоса, которая перемещается в зависимости от силы.
    pushMatrix();
    translate(x, y, z);
    //Увеличение
    if (intensity > 100) intensity = 100;
    scale(sizeX*(intensity/100), sizeY*(intensity/100), 20);
    
    //Создание "куба"
    box(1);
    popMatrix();
    
    //Вторая полоса, та, которая всегда одинакового размера:
    displayColor = color(scoreLow*0.5, scoreMid*0.5, scoreHi*0.5, scoreGlobal);
    fill(displayColor, (scoreGlobal/5000)*(255+(z/25)));
    
    pushMatrix();
    translate(x, y, z);
    
    //Увеличение:
    scale(sizeX, sizeY, 10);
    
    //Создание куба:
    box(1);
    popMatrix();
    
    z+= (pow((scoreGlobal/150), 2));
    if (z >= maxZ) {
      z = startingZ;  
    }
  }
}