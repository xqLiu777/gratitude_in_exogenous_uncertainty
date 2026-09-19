data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                             
}

parameters {
  // 群体水平参数 - 分两侧
  real mu_slo;                    // x<0侧的斜率群体均值
  real mu_gam;
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_slo;
  real<lower=0> sigma_gam;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_slo;                // x>=0侧的个体斜率扰动
  vector[S] z_gam;           // 个体指数扰动
  
  real<lower=0> sigma_obs;           
  real<lower=2> nu;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] slope = mu_slo + sigma_slo * z_slo;
  vector[S] gamma = mu_gam + sigma_gam * z_gam;
}

model {
  /* ---------- 群体水平先验 ---------- */

  // 斜率先验 - 分两侧
  mu_slo ~ normal(0, 30);          // x已标准化
  mu_gam ~ normal(1, 1);

  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_slo ~ normal(0, 15);
  sigma_gam ~ normal(0, 0.5);
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_slo ~ std_normal();
  z_gam ~ std_normal();
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  {
    vector[N] mu;
    // subject loop and trial loop
    for (n in 1:N) {
      
      int s = subject[n];
      
      // 符号保留法：提取 x 的符号 (-1 或 1)
      real x_sign = x[n] < 0 ? -1.0 : 1.0;
  
      // 对 x 的绝对值求 gamma 次方，然后乘回符号，保证单调性不变
      mu[n] = slope[s] * x_sign * pow(fabs(x[n]), gamma[s]);
    }
    
    // 向量化评估，极大提升 MCMC 采样效率
    y ~ student_t(nu, mu, sigma_obs);
  }
}

generated quantities {
  // ---------- 1. 后验预测值 ----------
  vector[N] y_rep;
  // ---------- 2. 逐点对数似然（loo包必需） ---------- 
  vector[N] log_lik;
  
  {
    for (n in 1:N) {
      int s = subject[n];
      real x_sign = x[n] < 0 ? -1.0 : 1.0; 
      real mu_gen = slope[s] * x_sign * pow(fabs(x[n]), gamma[s]);
      
      y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
      log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
    }
  }
}