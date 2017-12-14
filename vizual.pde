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

void setup()
{
 fullScreen(P3D); //Отображение в 3D на весь экран.
  background(0);
  minim = new Minim(this);
  song = minim.loadFile("пьесня.mp3");
  fft = new FFT(song.bufferSize(), song.sampleRate());
  song.play(0);
  
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
  //Изменение цвета экрана в зависимости от частот: 
  background(scoreLow/100, scoreMid/100, scoreHi/100);
}