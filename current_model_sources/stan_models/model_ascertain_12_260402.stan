data {
  int<lower=1> N;                           
  int<lower=1> S;                           
  array[N] int<lower=1, upper=S> subject;   
  vector<lower=0>[N] x;            // x在[2,8]之间
  vector[N] y;                              // y 在 [-50, 50] 之间
}

transformed data {
  // 【核心修改1】：缩放 X，使其最大值为 1。这样极大缓解了非线性带来的共线性
  real max_x = 8.0; 
  vector[N] x_scaled = x / max_x;
  vector[N] log_x_scaled = log(x_scaled);
}

parameters {
  // 群体水平均值
  real mu_slo;  
  real mu_gam;
  real mu_int;
  
  // 群体水平标准差
  real<lower=0> sigma_slo;
  real<lower=0> sigma_gam;
  real<lower=0> sigma_int;
  
  // 个体扰动项
  vector[S] z_slo;                
  vector[S] z_gam;           
  vector[S] z_int;           
  
  real<lower=0> sigma_obs;           
  real<lower=2> nu;
}

transformed parameters {
  // Stan 支持向量化运算，不需要写 for 循环，代码更短且运算更快！
  vector[S] slope = mu_slo + sigma_slo * z_slo; 
  vector[S] gamma = mu_gam + sigma_gam * z_gam;            
  vector[S] inter = mu_int + sigma_int * z_int;
}

model {
  /* ---------- 群体水平先验 ---------- */
  mu_slo ~ normal(0, 20);      // 允许斜率在较宽的范围内寻找合适的值
  mu_int ~ normal(0, 20);   
  mu_gam ~ normal(1, 0.5);          // gamma 落在 [-3, 3] 之间足够拟合绝大部分曲线了
      

  /* ---------- 变异参数先验 ---------- */
  sigma_slo ~ normal(0, 10);
  sigma_int ~ normal(0, 10); 
  sigma_gam ~ normal(0, 0.2);
  sigma_obs ~ normal(0, 10);   
  
  /* ---------- 个体水平先验 ---------- */
  z_slo ~ std_normal();
  z_gam ~ std_normal();
  z_int ~ std_normal();
  
  nu ~ gamma(2, 0.1);
  
  /* ---------- 似然函数 ---------- */
  {
    vector[N] mu;
    for (n in 1:N) {
      int s = subject[n];
      // 最纯粹的公式：slope * x^gamma + inter
      mu[n] = slope[s] * exp(gamma[s] * log_x_scaled[n]) + inter[s];
    }
    
    y ~ student_t(nu, mu, sigma_obs);
  }
}

generated quantities {
  vector[N] y_rep;
  vector[N] log_lik;
  
  for (n in 1:N) {
    int s = subject[n];
    real mu_gen = slope[s] * exp(gamma[s] *log_x_scaled[n]) + inter[s];
    
    y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
    log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
  }
}