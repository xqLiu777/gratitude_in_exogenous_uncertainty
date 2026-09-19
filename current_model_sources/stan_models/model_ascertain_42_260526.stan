data {
  int<lower=1> N;                           // 总观测数
  int<lower=1> S;                           // 被试数
  array[N] int<lower=1, upper=S> subject;   // 被试ID
  vector[N] x;                              // 自变量（必须已标准化：均值0，标准差1）
  vector[N] y;                              // 因变量（范围-50-50）
}

parameters {
  // 群体水平参数 - 分两侧
  real mu_int;                   // x<0侧的截距群体均值
  
  // 群体水平标准差 - 分两侧
  real<lower=0> sigma_int;
  
  // ---- 非中心参数化的核心 ----
  // 个体参数扰动项 - 分两侧
  vector[S] z_int;               // x<0侧的个体截距扰动
  
  real<lower=0> sigma_obs;        
  real<lower=2> nu;
  
  // 【新增】：产生精确 0 值的概率
  // real<lower=0, upper=1> theta;
}


transformed parameters {
  // 非中心参数化转换：将标准正态变量转换为实际个体参数
  vector[S] inter = mu_int + sigma_int * z_int;

}

model {
  /* ---------- 群体水平先验 ---------- */
  // 截距先验 - 分两侧
  mu_int ~ normal(0, 50);        // 根据y尺度调整

  
  /* ---------- 变异参数先验 ---------- */
  // 群体层标准差 - 分两侧
  sigma_int ~ normal(0, 15);
  sigma_obs ~ normal(0, 15);
  
  /* ---------- 个体水平先验 ---------- */
  // 非中心参数化先验 - 分两侧
  z_int ~ std_normal();
  
  // 自由度先验保持不变，因为它与 y 的量级无关
  nu ~ gamma(2, 0.1);
  
  // theta 的先验：beta(1, 1) 代表 0~1 之间的均匀分布
  // theta ~ beta(1, 1);
  
  {
    // 在局部环境 {} 里计算 mu，算完即焚，不占内存
    vector[N] mu;
    for (n in 1:N) {
      int s = subject[n];
      if (x[n] < 0) {
        mu[n] = inter[s];
      } else {
        mu[n] = inter[s];
      }
    }
    // 所有人，不管是不是 0，全部公平地服从这个厚尾分布
    target += student_t_lpdf(y | nu, mu, sigma_obs);
  }

}

generated quantities {
  // ---------- 1. 后验预测值 ----------
  vector[N] y_rep;
  // ---------- 2. 逐点对数似然（loo包必需） ---------- 
  vector[N] log_lik;
  
  {
    real mu_gen;
    for (n in 1:N) {
      int s = subject[n];
      
      
      // 根据 x 的正负，套用不同的参数
      if (x[n] < 0) {
        mu_gen = inter[s];
      } else {
        mu_gen = inter[s];
      }
      
      // 生成似然值和预测值
      log_lik[n] = student_t_lpdf(y[n] | nu, mu_gen, sigma_obs);
      y_rep[n] = student_t_rng(nu, mu_gen, sigma_obs);
    }
  }

}
